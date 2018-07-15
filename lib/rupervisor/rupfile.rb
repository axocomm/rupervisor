require 'rupervisor/context'

# TODO: Maybe make some components of this a common DSL-generating
# library?
module Rupervisor
  class Rupfile
    DEFAULT_PATH = File.join(Dir.pwd, 'Dupfile')

    attr_reader :path

    def initialize(path = DEFAULT_PATH)
      @path = path
    end

    def dump
      deploy! :dump
    end

    def deploy!(mode = :deploy)
      begin
        # Context.new(self, mode).run!
        Context.run_file!(self)
        puts "Would do a #{mode.to_s}"
      # TODO: Ensure actual handling of different exceptions.
      rescue Exception => e
        raise
      end
    end
  end
end
