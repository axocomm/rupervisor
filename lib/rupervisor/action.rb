require 'open3'

module Rupervisor
  class Action
    def run!
      raise NotImplementedError
    end
  end

  module Actions
    class Exit < Action
      attr_accessor :rv

      def initialize
        @rv = nil
      end

      def with(rv = 0)
        @rv = rv
        self
      end

      def call(last_rv = 0)
        rv = if @rv.nil?
               last_rv
             else
               @rv
             end

        Proc.new { exit rv }.call
      end
    end

    class Retry < Action
      def call
        puts 'Would retry'
      end
    end

    class RunScenario < Action
      def initialize(name)
        @name = name
      end

      def call
        s = Rupervisor::Scenario.by_name(@name)
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
        next_action
      end

      class ScenarioUndefined < StandardError
      end
    end

    class ActionUndefined < StandardError
    end
  end
end
