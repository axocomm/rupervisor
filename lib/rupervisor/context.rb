require 'open3'
require 'singleton'

require 'rupervisor/dsl'

module Rupervisor
  class Context
    include Singleton

    def initialize
      @last_run = nil
    end

    # Execute an action.
    #
    # TODO: This probably needs some better definition
    def run!(action)
      next_action = action.call(self)
      @last_run = action
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
