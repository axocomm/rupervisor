require 'open3'
require 'singleton'

require 'rupervisor/dsl'

module Rupervisor
  class Context
    include Singleton

    attr_reader :last_action, :last_result, :scenarios

    def initialize
      @last_run = nil
      @scenarios = {}
    end

    def register!(scenario)
      @scenarios[scenario.name] = scenario
    end

    # Execute an action.
    #
    # TODO: This probably needs some better definition
    def run!(action)
      result, next_action = action.call(self)

      @last_action = action
      @last_result = result

      if next_action
        run!(next_action)
      else
        puts "Done after #{action}"
      end
    end

    def run_file!(ruperfile)
      DSL.evaluate(ruperfile.content)
    end
  end
end
