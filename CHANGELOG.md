## [Unreleased]


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
