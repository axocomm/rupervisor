require 'rupervisor/action'
require 'rupervisor/context'
require 'rupervisor/errors'
require 'rupervisor/scenario'

module Rupervisor
  class DSL
    def initialize(mode)
      @mode = mode
    end

    def self.evaluate(content, mode)
      self.new(mode).instance_eval { eval(content) }
    end

    ##################
    # DSL Components #
    ##################

    class Scenario < Rupervisor::Scenario
      def initialize(name, &block)
        super(name)
        yield self
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

      def on(rv, action)
        if rv.is_a?(Array)
          rv.each { |code| @actions[code] = action }
        elsif rv == :any
          @default_action = action
        elsif rv.is_a?(Integer)
          @actions[rv] = action
        else
          raise Rupervisor::RuperfileError, "Unsupported return value #{rv}"
        end

        self
      end

      def otherwise(action)
        @default_action = action
        self
      end

      private

      def register!
        Context.instance.register!(self)
      end
    end

    def begin!(init = :init)
      Context.instance.run!(run(init)) if @mode == :run
    end

    # Top-level DSL functions for triggering actions

    def run(name)
      Actions::RunScenario.new(name)
    end

    def call(&block)
      Actions::Block.new(&block)
    end

    def just_exit
      Actions::Exit.new
    end

    def try_again(times = 1)
      Actions::Retry.new(times)
    end
  end
end
