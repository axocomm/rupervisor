require 'json'
require 'shellwords'

module Rupervisor
  # The Scenario class.
  #
  # A Scenario is the basic unit of work in a Ruperfile and is
  # primarily used for executing commands.
  #
  # Each Scenario should have at least a name and command. These and
  # other properties are set using the DSL-specific subclass that
  # provides some sentence-like chainable methods.
  class Scenario
    attr_reader :name, :command, :params, :actions, :default_action

    def initialize(name)
      @name = name
      @params = {}
      @actions = {}
      @default_action = nil
    end

    def prepared_command
      @command % Hash[@params.map { |(k, v)| [k, Shellwords.escape(v)] }]
    end

    def dump
      puts to_s
      @actions.each do |(code, action)|
        puts "  #{code}: #{action}"
      end
      puts "  default: #{@default_action}" unless @default_action.nil?
    end

    def to_s
      "Scenario[#{@name}]"
    end

    def to_h
      {
        name: @name,
        command: @command,
        params: @params,
        runnable_command: prepared_command,
        actions: @actions.merge(default: @default_action)
      }
    end

    def to_json(*)
      to_h.to_json
    end
  end
end
