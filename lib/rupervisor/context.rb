require 'open3'
require 'singleton'

require 'rupervisor/dsl'

module Rupervisor
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
        puts "Done after #{action}"
      end
    end

    def run_file!(ruperfile)
      DSL.evaluate(ruperfile.content)
    end
  end
end
