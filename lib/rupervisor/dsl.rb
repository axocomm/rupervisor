require 'rupervisor/action'
require 'rupervisor/context'
require 'rupervisor/scenario'

module Rupervisor
  class DSL
    def self.evaluate(content)
      self.new.instance_eval { eval(content) }
    end

    ##################
    # DSL Components #
    ##################

    class Scenario < Rupervisor::Scenario
      def initialize(name, &block)
        super(name)
        tap(&block)
        register!
      end

      def runs(command)
        @command = command
        self
      end

      # TODO: `using` for any extra parameters?
      def with(params)
        @params = params
        self
      end

      def on(code, action)
        @actions[code] = action
        self
      end

      def otherwise(action)
        @default_action = action
        self
      end

      private

      def register!
        Rupervisor::Scenario.register!(self)
      end
    end

    def begin!
      Context.instance.run!(Actions::RunScenario.new(:init))
    end

    def run(name)
      Actions::RunScenario.new(name)
    end

    def just_exit
      Actions::Exit.new
    end

    def try_again
      Actions::Retry.new
    end
  end
end
