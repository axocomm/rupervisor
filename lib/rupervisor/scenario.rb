require 'json'

module Rupervisor
  class Scenario
    attr_accessor :name, :command, :params, :outcomes

    def initialize(name, &block)
      @name = name
      @params = {}
      @outcomes = {}

      yield self

      register!
    end

    # TODO: Clean command somehow?
    def command
      @command % @params
    end

    # DSL components

    def runs(command)
      @command = command
      self
    end

    def with(params)
      @params = params
      self
    end

    # TODO: `using` for any extra parameters?

    # TODO: Determine step type here instead and store as [:type,
    # :val] to be executed appropriately?
    def on(code, step)
      @outcomes[code] = step
      self
    end

    def to_h
      {
        :name     => @name,
        :command  => @command,
        :params   => @params,
        :outcomes => @outcomes
      }
    end

    def to_json
      to_h.to_json
    end

    private

    def register!
      Context.register!(self)
    end
  end
end
