require 'rupervisor/context'

# TODO: Maybe make some components of this a common DSL-generating
# library?
module Rupervisor
  class Ruperfile
    DEFAULT_PATH = File.join(Dir.pwd, 'Dupfile')

    attr_reader :path

    def initialize(path = DEFAULT_PATH)
      @path = path
    end

    def content
      File.open(@path) { |fh| fh.read }
    end

    def dump
      run! :dump
    end

    def run!(mode = :run)
      begin
        # Context.new(self, mode).run!
        Context.instance.run_file!(self)
      # TODO: Ensure actual handling of different exceptions.
      rescue Exception => e
        raise
      end
    end
  end
end
