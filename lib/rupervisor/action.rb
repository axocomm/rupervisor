require 'open3'

require 'rupervisor/errors'

module Rupervisor
  # A base class for Rupervisor actions.
  #
  # Implementation must at a minimum include #call, which will
  # actually execute each action while running the Ruperfile.
  class Action
    def call(_ctx, _last_action, _last_result)
      raise NotImplementedError
    end

    def to_s
      'Action[]'
    end

    def to_h
      raise NotImplementedError
    end

    def to_json(*)
      to_h.to_json
    end
  end

  # TODO: Should these have analogues in the DSL class as well? Or is
  # that a stupid idea in general?
  module Actions
    # An Action that allows execution of a Block at runtime.
    class Block < Action
      attr_accessor :args

      def initialize(&block)
        @proc = proc(&block)
        @args = []
      end

      # TODO: Should at least last_result be injected automatically,
      # or perhaps with a special case of .with?
      def call(_ctx, _last_action, _last_result)
        @proc.call(*@args)
      end

      def with(*args)
        @args = args
        self
      end

      def to_s
        "Block[args=#{@args}]"
      end

      def to_h
        { type: 'Block', args: @args }
      end
    end

    # An Action triggering the job to exit.
    class Exit < Action
      attr_accessor :rv

      def initialize
        @rv = nil
      end

      def with(rv)
        @rv = rv
        self
      end

      def call(_ctx, _last_action, last_result)
        proc { |rv| exit rv }.call(@rv.nil? ? last_result : @rv)
      end

      def to_s
        "Exit[rv=#{@rv}]"
      end

      def to_h
        { type: 'Exit', rv: @rv }
      end
    end

    # An Action facilitating retries of another action.
    #
    # The #call method of Retry will repeatedly execute the action
    # that requested it until the number of attempts has been exceeded
    # or the result changes.
    class Retry < Action
      def initialize(attempts = 1)
        @max_attempts = attempts
        @attempt = 1
        @action = nil
        @result = nil
        @on_failure = nil
      end

      def then(action)
        @on_failure = action
        self
      end

      # NB: This mutates @action and @result to preserve the original
      # action (should be a RunScenario) that triggered it.
      def call(ctx, last_action, last_result)
        @action ||= last_action
        @result ||= last_result

        retry_action!(ctx, last_action, last_result)
      end

      # TODO: Is there any need to check that last_action == @action?
      def retry_action!(ctx, _last_action, last_result)
        puts "In retry, looking for #{@result} and got #{last_result}"
        result, next_action = @action.call(ctx, @action, last_result)
        if result != @result
          puts 'Result changed; done retrying'
          [result, next_action]
        elsif @attempt <= @max_attempts
          puts 'Retrying'
          @attempt += 1
          [result, self]
        else
          puts 'Retries exhausted'
          [result, @on_failure]
        end
      end

      def to_s
        "Retry[max_attempts=#{@max_attempts},on_failure=#{@on_failure}]"
      end

      def to_h
        {
          type: 'Retry',
          max_attempts: @max_attempts,
          on_failure: @on_failure
        }
      end
    end

    # An Action that executes the command registered in a Scenario.
    class RunScenario < Action
      def initialize(name)
        @name = name
      end

      # TODO: last_result used for passing around stdin/stdout/stderr
      # as well?
      def call(ctx, _last_action, _last_result)
        s = ctx.scenarios[@name]
        raise ScenarioUndefined, "Scenario #{@name} not defined" if s.nil?

        status = Open3.popen3(s.prepared_command) do |_, out, err, t|
          puts '----'
          puts "command: #{s.prepared_command}\n\n"
          puts "stdout:\n#{out.read}\n"
          puts "stderr:\n#{err.read}\n"
          t.value
        end
        rv = status.exitstatus
        puts "return code: #{rv}"

        next_action = s.actions[rv] || s.default_action
        raise ActionUndefined, "No action defined for #{rv}" if next_action.nil?
        [rv, next_action]
      end

      def to_s
        "RunScenario[name=#{@name}]"
      end

      def to_h
        {
          type: 'RunScenario',
          scenario: @name
        }
      end
    end
  end
end
