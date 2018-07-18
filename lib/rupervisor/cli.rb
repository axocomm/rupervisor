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

    option :format, type: :string, default: :simple, aliases: [:f]
    desc 'inspect RUPERFILE', 'Dump contents of RUPERFILE'
    def inspect_rup(ruperfile = Ruperfile.default_path)
      Ruperfile.new(ruperfile).dump(mode: options[:format].to_sym)
    end
  end
end
