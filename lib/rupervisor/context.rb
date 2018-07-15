require 'open3'

module Rupervisor
  # TODO: Don't make this all static?
  class Context
    @@scenarios = {}
    @@last_run = nil

    def self.register!(scenario)
      @@scenarios[scenario.name] = scenario
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
    def self.run!(name)
      s = @@scenarios[name]
      raise ScenarioUndefined, "No scenario named #{name}" if s.nil?

      status = Open3.popen3(s.command) do |_, out, err, t|
        puts '----'
        puts "command: #{s.command}\n\n"
        puts "stdout:\n#{out.read}\n"
        puts "stderr:\n#{err.read}\n"
        t.value
      end
      puts "return code: #{status.exitstatus}"

      @@last_run = name
    end
  end

  class ScenarioUndefined < StandardError
  end
end