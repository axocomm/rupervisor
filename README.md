# rupervisor

rupervisor is a DSL and CLI tool that executes commands and performs
actions based on their return values, and enables the definition of
simple pipelines for anything. Be aware this is still in very early
development and might have some strange behavior.

## How it Works

Configuration is done inside a `Ruperfile` using Ruby and a small
"DSL" for defining scenarios and outcomes. For example,

``` ruby
API_DOWN = 2

def log_file(suffix = '')
  '/tmp/foo#{suffix}.log'
end

COMMAND = './tmp/foo -s %<seq_start>d %<wait_api>s > %<log_file>s 2>&1'

attempt = 1

Scenario.new(:init) do |s|
  args = {
    :seq_start => 1,
    :log_file  => log_file
  }

  s.runs(COMMAND).with(args)
  s
    .on(0, just_exit)
    .on(1, just_exit)
    .on(API_DOWN, :run_again)
end

Scenario.new(:run_again) do |s|
  attempt += 1

  args = {
    :seq_start => next_seq_start,
    :log_file  => log_file(attempt),
    :wait_api  => '-w'
  }

  s.runs(COMMAND).with(args)
  s
    .on(0, just_exit)
    .on(1, just_exit)
    .on(API_DOWN, :run_again)
end

begin!
```

This file (maybe not the best example yet) defines `Scenario`s named
`:init` and `:run_again`. A `Scenario` simply contains a command, some
options/arguments, and a number of handlers that are executed
depending on the command's exit code. `begin!` triggers the `Context`
to begin execution of a starting `Scenario` (by default `:init`). When
the command exits, the action specified in the `.on` call will be run,
whether it be just exiting (`just_exit`) or attempting another
action (Ruby block, `Scenario`, exiting, retrying).

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
    - Default actions, e.g. automatically exiting if no handlers are
      defined
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
