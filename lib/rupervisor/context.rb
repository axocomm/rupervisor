require 'open3'
require 'singleton'

module Rupervisor
  # The Context class.
  #
  # This class is a singleton that primarily handles registration and
  # execution of Ruperfile Scenarios.
  class Context
    include Singleton

    attr_reader :scenarios

    def initialize
      @scenarios = {}
    end

    def register!(scenario)
      @scenarios[scenario.name] = scenario
    end

    # Execute an action.
    #
    # TODO: This probably needs some better definition
    def run!(action, last_action = nil, last_result = nil)
      result, next_action = action.call(self, last_action, last_result)

      if next_action
        run!(next_action, action, result)
      else
        puts "Done after #{action} with #{result}"
      end
    end

    # Dump registered scenarios.
    def dump
      @scenarios.values.each(&:dump)
    end

    def to_h
      { scenarios: @scenarios }
    end

    def to_json(*)
      to_h.to_json
    end
  end
end
