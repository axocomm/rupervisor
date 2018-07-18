require 'rupervisor/ruperfile'

require 'thor'

module Rupervisor
  class CLI < Thor
    include Rupervisor

    class_option :verbose, type: :boolean, aliases: [:v]

    def initialize(*args)
      super
      # configure_logging!
    end

    desc 'run RUPERFILE', 'Run a job'
    def run_rup(ruperfile = Ruperfile.default_path)
      Ruperfile.new(ruperfile).run!
    end

    option :json, type: :boolean, aliases: [:j]
    desc 'inspect RUPERFILE', 'Dump contents of RUPERFILE'
    def inspect_rup(ruperfile = Ruperfile.default_path)
      format = options[:json] ? :json : :simple
      Ruperfile.new(ruperfile).dump(format: format)
    end
  end
end
