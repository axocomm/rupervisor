require 'rupervisor/dsl'

# TODO: Maybe make some components of this a common DSL-generating
# library?
module Rupervisor
  class Ruperfile
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
        DSL.evaluate(content)
      rescue RuperfileError => e
        puts "!!! There was a problem in #{basename}: #{e}"
      rescue StandardError => e
        raise
      end
    end

    def basename
      File.basename(@path)
    end

    def self.default_path
      File.join(Dir.pwd, 'Ruperfile')
    end
  end
end
