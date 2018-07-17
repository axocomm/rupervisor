require 'rupervisor/ruperfile'

require 'thor'

module Rupervisor
  class CLI < Thor
    include Rupervisor

    class_option :verbose, type: :boolean, aliases: %i(v)

    def initialize(*args)
      super
      # configure_logging!
    end

    desc 'run RUPERFILE', 'Run a job'
    def run_rup(ruperfile = Ruperfile.default_path)
      Ruperfile.new(ruperfile).run!
    end
  end
end
