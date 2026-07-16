# AGENTS.md

Reference for AI agents (and humans) working in this repo. A Ruby gem implementing
simulated annealing. See `README.md` for the public API and configuration precedence
(global < instance < just-in-time).

## Commands

- Setup: `bin/setup` (runs `bundle install`).
- Full default check (order matters): `bundle exec rake` — runs `test`, then `end_to_end_test`, then `rubocop`.
- Run tests only: `bundle exec rake test`.
- Run a single test file: `bundle exec ruby -Ilib:test test/path/to_test.rb` (or `rake test TEST=...`).
- Lint only: `bundle exec rubocop` (or `bundle exec rake rubocop`).
- Interactive console: `bin/console`. Runnable demo: `bin/run`.

## Gotchas

- `rake`'s default task includes `bin/run` via the `end_to_end_test` task. It runs a
  real (slow, non-deterministic due to `rand`) annealing simulation; skip it with
  `rake test rubocop` when you only want fast feedback.
- Tests use Minitest. `test/test_helper.rb` requires `ruby-prof` and `debug` — both are
  dev deps in the `Gemfile`; ensure they're installed (`bundle install`) before running tests.
- `Annealing.configuration` is a global singleton. Tests reset it in
  `Minitest::Test#teardown` by setting `Annealing.configuration = nil`. When writing
  tests that touch global config, favor scoped instance/JIT config or rely on teardown.
- `Metal#cool!` is non-idempotent and depends on `rand`; never assume deterministic
  output from a single run.
- `Simulator#run` raises `ConfigurationError` ( subclass of `Annealing::Error`) on
  invalid config; validation happens lazily at run time, not at `Simulator.new`.

## Style / rubocop

- Inherited from `.rubocop.yml` + `.rubocop_todo.yml`. `TargetRubyVersion: 3.4`,
  `Layout/LineLength: Max 120`, double-quoted strings, NewCops enabled with rubocop-
  performance/-minitest/-rake plugins loaded.
- CI lint job runs `bundle exec rubocop --parallel` on Ruby 4.0; test matrix is 3.4/4.0
  (see `.github/workflows/ruby.yml`). Keep code compatible with 3.4.

## Architecture

- Entry: `Annealing.simulate` (lib/annealing.rb) — thin wrapper over
  `Annealing::Simulator.new(...).run(...).state`.
- `Simulator` (lib/annealing/simulator.rb) drives the loop, merging configs at runtime
  and calling `Metal#cool!` each step until `termination_condition` returns truthy.
- `Metal` (lib/annealing/metal.rb) holds current `state`, `temperature`, and lazily
  computed `energy`; `cool!` applies the probabilistic accept/reject step.
- `Configuration` (lib/annealing/configuration.rb) plus concrete
  `Configuration::Coolers` and `Configuration::Terminators` provide built-in callables.

## Release

Bump `lib/annealing/version.rb`, then `bundle exec rake release` (tags, pushes, releases
to rubygems.org; `rubygems_mfa_required` is set in the gemspec).