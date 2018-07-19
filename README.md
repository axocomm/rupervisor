# rupervisor

rupervisor is a DSL and CLI tool that executes commands and performs
actions based on their return values, and enables the definition of
simple pipelines for anything. Be aware this is still in very early
development and might have some strange behavior.

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

## Usage

### `Ruperfile` DSL

Configuration is done inside a `Ruperfile` using Ruby and a small
"DSL" for defining scenarios and outcomes using functions and chained
methods that read vaguely like sentences.

#### `Scenario`

Steps are implemented using the `Scenario` class. Its constructor
takes the name of the step and a block defining its properties, to
which it yields itself. Commands to run and actions to take are
defined inside this block by using several DSL methods and functions:

- `.runs(command)`

    Sets the command (or command format string) that will be run

- `.with(params)`

    Accepts a Hash of parameters that will be formatted into the
    command

- `.on(code, action)`

    Registers a handler for an execution outcome

    This accepts one of the following:

    - An integer registers the handler for a single exit code
    - An array of integers registers the handler for several exit
      codes
    - The symbol `:any` registers the handler for all codes (identical
      to `.otherwise`)

- `.otherwise(action)`

    Registers a default handler to execute if one is not registered
    for the exit code

Each of these methods returns the `Scenario` instance, so they are
encouraged to be chained.

#### Actions

When a step's command exits, the return code is checked and one of a
number of actions may be taken, specified by the use of a few helper
functions:

- `run(name)`

    Runs another `Scenario` by name

- `just_exit`

    Returns an `Exit` action that exits the program. By default, this
    will use the exit code of the command but may be overridden using
    `Exit.with`, e.g. `just_exit.with(1)`.

- `try_again([times = 1])`

    Retries the current scenario a specified number of times

    By default, when all retries are exhausted the program will just
    exit normally. However, by calling `.then(action)`, and
    alternative may be provided (e.g. running another scenario,
    exiting with a specific code, etc.).

- `call(&block)`

    Executes a Ruby block

    If the block takes arguments, they may be provided with `.with`,
    e.g. `call { |x| puts "Called with #{x}" }.with(42)`.

    Soon I would like to make command execution results (exit code,
    stdout, stderr) to these blocks for custom error handling, etc.

#### Example

``` ruby
Scenario.new(:init) do |s|
  s.runs('./hello %<name>s').with(name: 'Foo')
   .on(0, run(:another_step))
   .otherwise(try_again(1).then(just_exit.with(1)))
end

Scenario.new(:another_step) do |s|
  s.runs('./goodbye')
   .on(:any, just_exit)
end

begin!
```

This simplistic example registers a new `Scenario` called `:init`
which runs the command `'./hello %<name>s' % { name:
Shellwords.escape('Foo') }`. If the command returns 0, the pipeline
proceeds to another step. Otherwise, it tries again once before just
exiting with 1.

Finally, `begin!` serves to trigger the first scenario and accepts an
optional symbol for specifying the entry point.

As this is simply Ruby, blocks in the `Scenario` definition may be
used to dynamically populate arguments (e.g. determining where to
start from next), more finely control retry counts, implement simple
alerting and monitoring, etc.

### Running a file

After specifying your scenarios as above, simply run `rp run`. This
will execute `Ruperfile` by default, but a different path or filename
may be provided as a positional argument.

### Inspecting a file

To see how the program will interpret the `Ruperfile` definition, the
`rp inspect` command may be run. This command accepts an optional
`--format, -f FORMAT` option accepting `json`, `yaml`, or `simple`
(default).

JSON and YAML output includes all `Scenario`s (along with registered
return code handlers and commands), e.g.

``` yaml
---
path: simple.ruper
context:
  scenarios:
    init:
      name: init
      command: "./hello %<name>s"
      params:
        name: Foo
      runnable_command: "./hello Foo"
      actions:
        '0':
          type: RunScenario
          scenario: another_step
        default:
          type: Retry
          max_attempts: 1
          on_failure:
            type: Exit
            rv: 1
    another_step:
      name: another_step
      command: "./goodbye"
      params: {}
      runnable_command: "./goodbye"
      actions:
        default:
          type: Exit
          rv:
```

whereas using `simple` will display a much simpler outline just
containing scenarios and actions on return code:

```
Scenario[init]
  0: RunScenario[name=another_step]
  default: Retry[max_attempts=1,on_failure=Exit[rv=1]]
Scenario[another_step]
  default: Exit[rv=]
```

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
    - Setting actions based on output content as well?
    - Better syntax for running subsequent `Scenario`s
    - Ability to pass arguments and/or provide rules for generating
      them on subsequent runs
    - Binding of output and exit code for Block Actions?
    - Renaming `Scenario` to something more appropriate?
- Actual error handling
- Ability to define scenarios elsewhere and include them (even if it's
  just a friendlier DSL method for `require_relative`)
- Ability to pipe stderr or stdout to actions
- Cleanup/atexit actions
- Lazy evaluation for computing things during actual scenario
  execution
