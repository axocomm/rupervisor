require 'thor'

module Rupervisor
  class CLI < Thor
    include Rupervisor

    class_option :verbose, type: :boolean, aliases: %i(v)

    def initialize(*args)
      super
      # configure_logging!
    end

    desc 'run RUPFILE', 'Run a job'
    def run_rup(rupfile = 'Rupfile')
      puts "Yo, it's #{rupfile}"
    end
  end
end
