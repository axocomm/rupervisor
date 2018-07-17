require 'open3'

require 'rupervisor/errors'

module Rupervisor
  class Action
    def call(_ctx, _last_action, _last_result)
      raise NotImplementedError
    end
  end

  module Actions
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
        rv = @rv.nil? ? last_result : @rv
        Proc.new { exit rv }.call
      end
    end

    class Retry < Action
      def initialize(attempts = 1)
        @max_attempts = attempts
        @attempt = 1
        @action = nil
        @result = nil
        @on_failure = nil  # TODO: Maybe a .then with another action?
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
    end

    class RunScenario < Action
      def initialize(name)
        @name = name
      end

      def call(ctx, last_action, last_result)
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
    end
  end
end
