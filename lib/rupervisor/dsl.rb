require 'rupervisor/context'

module Rupervisor
  class DSL
    def self.evaluate(ctx, content)
      self.new.instance_eval { eval(content) }
    end

    ##################
    # DSL Components #
    ##################

    class Scenario
      def initialize(name, &block)
        # TODO: Use .tap?
        Rupervisor::Scenario.new(name, &block).register!
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
