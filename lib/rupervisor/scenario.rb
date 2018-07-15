require 'json'

module Rupervisor
  class Scenario
    attr_reader :name, :command, :params, :outcomes, :default_outcome

    def initialize(name)
      @name = name
      @params = {}
      @outcomes = {}
      @default_outcome = nil
    end

    # TODO: Clean command
    def prepared_command
      @command % @params
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
  end
end
