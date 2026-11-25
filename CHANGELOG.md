## Next

- Fix bug where worse states were always accepted once the temperature went negative (#37)
- **Potentially breaking:** stricter configuration validation (#40)
  - Unknown config keys raise `ConfigurationError` instead of being silently ignored
  - `temperature` and `cooling_rate` must be finite floats (integers are converted); `cooling_rate`
    must be positive (`0` used to loop forever) and `temperature` non-negative
  - `Coolers.geometric` requires a finite ratio of at least 1.0
- Rename `Metal#lower_energy?` to `Metal#energy_greater_than?` (#39)
- Avoid a redundant `energy_calculator` call when `return_best` is true (#38)
- Fix README examples and `return_best` default description, and the "algoritm" typo (#39)
- Bump json to 2.21.2 for a use-after-free fix (#36) and refresh development dependencies
- BREAKING: normalize the custom function interfaces (closes #17). The
  `energy_calculator`, `state_change`, `cool_down`, and `termination_condition`
  functions now each receive a single `Annealing::Step` argument instead of
  their previous positional arguments. See the README for the new signatures.
  Thanks to @webbrain-one for the original implementation in #35.

## [0.4.1] - 2026-07-16

- Add return_best config option. When true, returns the best (lowest energy) state. When false, returns the final state (preserves old behavior).
- Bump minimum supported Ruby version to 3.4.0 and add Ruby 4.0 support.
- Refresh development dependencies (rubocop, ruby-prof, and plugins) to versions
  compatible with Ruby 4.0.
- Bump RuboCop `TargetRubyVersion` to 3.4 and CI test matrix to 3.4 / 4.0.

## [0.4.0] - 2023-03-09

- Rename method and add comments to clarify use by @chrisbloom7 in #20
- Config Cleanup: remove logger config by @chrisbloom7 in #21
- Simply configuration and overrides by @chrisbloom7 in #22
- Idea: Add library of built-in functions by @chrisbloom7 in #23

## [0.3.0] - 2022-02-21

- Removed the default state change function; you are now required to define a custom `state_change` function for the simulation (#2)
- Added support for specifying a custom `termination_condition` function to override the default condition of the temperature reaching 0 (#5)
- Added support for specifying a custom `cool_down` function to override the default linear cooling function (#9)
- Normalized configurations options such that they can be specified in a consistent way across many interfaces (#19)
- `Annealing::Pool` has been replaced with `Annealing::Metal` which has a different interface from the old class
- `Annealing.simulate`, `Annealing::Simulator.new` and `Annealing::Simulator#run` method signatures have changed to accommodate normalized configuration options
- `Annealing::Simulator.new` no longer raises `RuntimeError` exceptions if configuration options are invalid. Instead, they will be raised from `Annealing::Simulator#run` as `ArgumentError` exceptions.
- Negative `cooling_rate` values are no longer valid; `Annealing::Simulator#run` will raise an error if one is specified
- Comprehensive test suite added

## [0.2.0] - 2020-07-23

- Improve private methods
- Minor code cleanup

## [0.1.0] - 2020-07-17

- It allows custom configuration
- It use distance method to calculate energy
- It allows user to implement their own total energy calculator
