require 'json'
require 'yaml'

require 'rupervisor/dsl'

# TODO: Maybe make some components of this a common DSL-generating
# library?
module Rupervisor
  # The Ruperfile class.
  #
  # This class just serves as a reference to the current Ruperfile and
  # facilitates inspection and evaluation of its contents.
  class Ruperfile
    attr_reader :path

    def initialize(path = DEFAULT_PATH)
      @path = path
    end

    def content
      File.open(@path, &:read)
    end

    def dump(params = {})
      run!(mode: :simulate)

      dump_mode = params[:mode] || :simple
      case dump_mode
      when :json
        puts to_json
      when :yaml
        puts to_yaml
      else
        Context.instance.dump
      end
    end

    def run!(params = {})
      mode = params[:mode] || :run

      begin
        DSL.evaluate(content, mode)
      rescue RuperfileError => e
        puts "!!! There was a problem in #{basename}: #{e}"
      rescue StandardError
        raise
      end
    end

    def basename
      File.basename(@path)
    end

    def to_h
      { path: @path, context: Context.instance }
    end

    def to_json(*)
      to_h.to_json
    end

    def to_yaml(*)
      JSON.parse(to_json).to_yaml
    end

    def self.default_path
      File.join(Dir.pwd, 'Ruperfile')
    end
  end
end
