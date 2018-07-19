require 'rupervisor/action'
require 'rupervisor/context'
require 'rupervisor/errors'
require 'rupervisor/scenario'

module Rupervisor
  # A class primarily for handling evaluation of the Ruperfile and
  # exposing main DSL components.
  #
  # When #evaluate is called, a new instance of DSL is created with a
  # flag effectively enabling or disabling the operation of begin!
  # (which is probably unnecessary). In the context of this instance,
  # the DSL-specific Scenario class and helper methods are made
  # available and serve as the specification of the language itself.
  class DSL
    def initialize(mode)
      @mode = mode
    end

    def self.evaluate(content, mode)
      new(mode).instance_eval { eval(content) }
    end

    ##################
    # DSL Components #
    ##################

    # A DSL-specific subclass of Rupervisor::Scenario.
    #
    # This version of the Scenario class is what is exposed in the
    # Ruperfile and provides a "friendlier" interface to Scenario
    # definition, e.g. the chained methods for setting commands and
    # arguments and a &block parameter in the constructor for setting
    # those properties more declaratively.
    class Scenario < Rupervisor::Scenario
      def initialize(name)
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
