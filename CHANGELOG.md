## [Unreleased]

- Removed the default state change function; you are now required to define a custom `state_change` function for the simulation (#2)
- Added support for specifying a custom `termination_condition` function to override the default condition of the temperature reaching 0 (#5)
- Added support for specifying a custom `cool_down` function to override the default linear cooling function (#9)
- `Annealing::Pool` replaced with `Annealing::Metal` which has a different interface from the old class
- `Annealing::Simulator#run` method arguments changed to accomodate custom functions
- `Annealing::Simulator.new` no longer accepts negative `cooling_rate` arguments; it will raise an error if one is specified
- `Annealing::Simulator.new` now raises exceptions as `ArgumentError` instead of `RuntimeError` when invalid arguments are specified
- Comprehensive test suite added

## [0.2.0] - 2020-07-23

- Improve private methods
- Minor code cleanup

## [0.1.0] - 2020-07-17

- It allows custom configuration
- It use distance method to calculate energy
- It allows user to implement their own total energy calculator
