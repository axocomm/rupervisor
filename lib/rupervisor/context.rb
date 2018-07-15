require 'open3'
require 'singleton'

require 'rupervisor/dsl'
require 'rupervisor/scenario'

module Rupervisor
  class Context
    include Singleton

    def initialize
      @scenarios = {}
      @last_run = nil
    end

    def register!(scenario)
      @scenarios[scenario.name] = scenario
    end

    # Execute a Scenario by name.
    #
    # This looks up a Scenario by name and if found, runs its
    # specified command (with arguments injected), and after a
    # successful execution, it is set as the @@last_run.
    #
    # After execution, the return code is checked and the appropriate
    # action (calling another Scenario, retrying the same one,
    # exiting) is run.
    def run!(name)
      s = @scenarios[name]
      raise ScenarioUndefined, "No scenario named #{name}" if s.nil?

      status = Open3.popen3(s.command) do |_, out, err, t|
        puts '----'
        puts "command: #{s.command}\n\n"
        puts "stdout:\n#{out.read}\n"
        puts "stderr:\n#{err.read}\n"
        t.value
      end
      rv = status.exitstatus
      puts "return code: #{rv}"

      @last_run = name

      ns = s.outcomes[rv]
      raise OutcomeUndefined, "No outcome registered for #{rv}" if ns.nil?

      run_next! ns
    end

    def run_next!(next_step)
      if next_step.is_a?(Symbol)
        run! next_step
      elsif next_step.is_a?(Exit)
        next_step.call
      else
        puts "Don't know what #{next_step} is"
      end
    end

    def run_file!(ruperfile)
      DSL.evaluate(self, ruperfile.content)
    end
  end

  class Exit
    def initialize
      @rv = 0
    end

    def with(rv = 0)
      @rv = rv
      self
    end

    def call
      Proc.new { exit @rv }.call
    end
  end

  class ScenarioUndefined < StandardError
  end

  class OutcomeUndefined < StandardError
  end
end
