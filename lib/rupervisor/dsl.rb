require 'rupervisor/context'
require 'rupervisor/scenario'

module Rupervisor
  class DSL
    def self.evaluate(ctx, content)
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

      def on(code, step)
        @outcomes[code] = step
        self
      end

      def otherwise(step)
        @default_outcome = step
        self
      end

      private

      def register!
        Context.instance.register!(self)
      end
    end

    def begin!
      Context.instance.run! :init
    end

    def just_exit
      Exit.new
    end

    def try_again
      Retry.new
    end
  end
end
