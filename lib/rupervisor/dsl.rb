require 'rupervisor/context'

module Rupervisor
  class DSL
    class Scenario
      def initialize(name, &block)
        Rupervisor::Scenario.new(name, &block)
      end
    end

    def begin!
      Context.instance.run! :init
    end

    def self.evaluate(ctx, content)
      self.new.instance_eval { eval(content) }
    end
  end
end
