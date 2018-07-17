# rupervisor

rupervisor is a DSL and CLI tool that executes commands and performs
actions based on their return values, and enables the definition of
simple pipelines for anything. Be aware this is still in very early
development and might have some strange behavior.

## How it Works

Configuration is done inside a `Ruperfile` using Ruby and a small
"DSL" for defining scenarios and outcomes. As a contrived example,

``` ruby
API_DOWN = 5
HOST_UNREACHABLE = 6

def log_file(suffix = '')
  "/tmp/testlog#{suffix}.log"
end

def next_seq_start
  # ...
end

commands = {
  init: './tmp/foo -s %<seq_start>d > %<log_file>s 2>&1',
  check_api: "curl https://foo.com/api | head -1 | grep -qs '200 OK'"
}

Scenario.new(:init) do |s|
  args = { seq_start: next_seq_start, log_file: log_file }

  s.runs(commands[s.name]).with(args)
  s
    .on(0, run(:process_results))
    .on(API_DOWN, run(:check_api))
    .otherwise(just_exit)
end

Scenario.new(:check_api) do |s|
  s.runs(commands[s.name])
  s
    .on(0, run(:init))
    .on(HOST_UNREACHABLE, just_exit.with(1))
    .otherwise(try_again(5).then(just_exit))
end

Scenario.new(:process_results) do |s|
  args = { ... }
  s.runs(...).with(args)
  s
    .on(0, run(:generate_report))
    .otherwise(just_exit)
end

# Scenario.new(:generate_report) ...

begin!
```

This file defines a few `Scenario`s, i.e. pipeline steps (the
nomenclature might need some work) that interact as follows:

**`:init`**

`:init` runs a command with some arguments. When the program exits,
one of the following occurs depending on the exit code:

- If it is 0, `:process_results` is run.
- If the theoretical script returns `API_DOWN`, indicating
  short-term downtime of some kind, `:check_api` is run.
- Otherwise, the pipeline exits with the original return code.

**`:check_api`**

`:check_api` checks the response code of the API using `curl` and
waits for a 200.

- If the command succeeds, `:init` is run again.
- If the host is unreachable, the pipeline exits with an exit code of
  1.
- Otherwise, this step is tried again 5 times before just exiting.

**`:process_results`**

As a final step, `:process_results` does some imaginary processing and
either runs another `Scenario` or exits.

A `Scenario` simply contains a command, some options/arguments, and a
number of handlers that are executed depending on the command's exit
code. `begin!` triggers the `Context` to start execution of an initial
`Scenario` (by default `:init`). When the command exits, the action
specified in the `.on` call will be run, whether it be just exiting
(`just_exit`), attempting another action (`run`), or retrying
(`try_again`) (more might be added soon).

As this is simply Ruby, blocks in the `Scenario` definition may be
used to dynamically populate arguments (e.g. determining where to
start from next), more finely control retry counts, implement simple
alerting and monitoring, etc.

## Requirements

- Ruby 1.9.3+

## Installation

### From Source

1. Clone this repository
2. Install Rake with `bundle`
3. Run `rake` to build and install the Gem

### In a `Gemfile`

Simply add the following to your `Gemfile`:

``` ruby
gem 'rupervisor', github: 'axocomm/rupervisor'
```

## Running

After specifying your scenarios as above, simply run `rup run`. This
will execute `Ruperfile` by default, but a different path or filename
may be provided as a positional argument.

## Why?

Aside from just wanting to experiment a little more with writing DSLs,
this tool came out of wanting a quick way to define simple pipelines
and handle various outcomes of scripts and commands -- especially
those producing intermittent (but sometimes eventually recoverable)
errors or requiring manual intervention to resume properly -- without
the need to constantly check up on them.

## TODO

- Logging
- DSL improvements, including
    - Setting a single action for multiple exit codes
    - Setting actions based on output content as well?
    - Better syntax for running subsequent `Scenario`s
    - Ability to pass arguments and/or provide rules for generating
      them on subsequent runs
    - Ability to pass blocks as handlers
    - Renaming `Scenario` to something more appropriate?
- Actual error handling
- Updates to internal structure (e.g. generating a digraph of actions
  connected by outcomes?)
- Ability to dump evaluated `Ruperfile` to some easily-readable format
- Ability to define scenarios elsewhere and include them (even if it's
  just a friendlier DSL method for `require_relative`)
- Ability to pipe stderr or stdout to actions?
- Addressing code style concerns
- Cleanup/atexit actions
