require 'json'

module Rupervisor
  class Scenario
    attr_reader :name, :command, :params, :actions, :default_action

    def initialize(name)
      @name = name
      @params = {}
      @actions = {}
      @default_action = nil
    end

    # TODO: Clean command
    def prepared_command
      @command % @params
    end

    def dump(mode = :simple)
      puts to_s
      @actions.each do |(code, action)|
        puts "  #{code}: #{action.to_s}"
      end
    end

    def to_s
      "Scenario[#{@name}]"
    end

    def to_h
      {
        :name    => @name,
        :command => @command,
        :params  => @params,
        :actions => @actions
      }
    end

    def to_json(*)
      to_h.to_json
    end
  end
end
