# Annealing

[![Gem Version](https://badge.fury.io/rb/annealing.svg)](https://badge.fury.io/rb/annealing)
[![Ruby](https://github.com/3zcurdia/annealing/actions/workflows/ruby.yml/badge.svg)](https://github.com/3zcurdia/annealing/actions/workflows/ruby.yml)

Find the optimal solution in a complex problem through a simulated annealing implementation for Ruby objects.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'annealing'
```

And then execute:

```shell
bundle install
```

Or install it yourself as:

```shell
gem install annealing
```

## Usage

Simulated annealing algorithms work by comparing multiple permutations of a given object and measuring their relative efficiencies based on any number of competing factors. If you aren't already familiar with the concept of simulated annealing, we recommend watching [The Most Metal Algorithm in Computer Science](https://www.youtube.com/watch?v=I_0GBWCKft8) from [SciShow](https://www.youtube.com/c/SciShow) as it will help you understand some of the concepts and terms used below.

In order to use this algorithm, we must first define three things:

1. An initial object state to evaluate.
2. A way to measure the energy of that state.
3. A way to change the state of the object over time.

Let's use the traveling salesperson problem as an example. First, we will define a `Location` object with a `distance` method to measure the distance between two locations.

```ruby
Location = Struct.new(:x, :y) do
  def inspect
    "(#{x},#{y})"
  end

  def distance(location)
    dx = (x - location.x).abs
    dy = (y - location.y).abs
    Math.sqrt(dx**2 + dy**2)
  end
end
```

Now we can create an array of locations the salesperson will visit. This is our initial state, and the order can be any random starting state.

```ruby
locations = [
  Location.new(60, 200),
  Location.new(180, 200),
  Location.new(40, 120),
  Location.new(100, 120),
  Location.new(20, 40)
].shuffle
```

Next, we need a way to calculate the total energy of traveling to each location in turn, with low-energy states preferable to high-energy states. Think of it as a representation of the efficiency of the trip; the farther apart two points are, the less efficient the trip is.

```ruby
energy_calculator = lambda do |step|
  step.state.each_cons(2).sum do |location1, location2|
    location1.distance(location2)
  end
end
```

Finally, we need a way to make small, random changes in the order of locations the salesperson will visit as we probe for an optimal route.

```ruby
state_change = lambda do |step|
  locations = step.state
  size = locations.size
  swapped = locations.dup
  idx_a = rand(size)
  idx_b = rand(size)
  swapped[idx_b], swapped[idx_a] = swapped[idx_a], swapped[idx_b]
  swapped
end
```

Now we can run the simulation. With the default configuration, it will consider about 33 million proposed states, so this may take several minutes to complete.

```ruby
optimal_route = Annealing.simulate(locations,
                                   energy_calculator: energy_calculator,
                                   state_change: state_change)
optimal_route.map(&:to_a)
# => [[20, 40], [40, 120], [100, 120], [60, 200], [180, 200]]
```

## Configuration options

The annealer supports a number of configuration options. See the [configuration precedence](#configuration-precedence) section below for information on the different scopes they can be applied to.

### The step object

Each of the custom functions described below (`cool_down`, `energy_calculator`, `state_change`, and `termination_condition`) accepts a single argument: an `Annealing::Step` snapshot of the current iteration of the simulation. It exposes the following read-only methods:

- `state` — the current state of the `Metal` being evaluated
- `energy` — the energy calculation of the current state
- `temperature` — the current temperature of the annealer
- `cooling_rate` — the `cooling_rate` in effect for this simulation
- `steps` — the number of steps the annealer has taken so far (`0` for the initial state)

Within one pass of the simulation, `termination_condition` and `state_change` see the count of completed steps, while `cool_down` sees the count including the step it is about to perform. The count advances on every step, whether or not the proposed state is accepted.

### `cool_down`

By default, the simulation will decrease the `temperature` linearly by `cooling_rate` on each step of the annealing process. In some cases you may wish to override this to use a different cooling algorithm. To do so, you can use one of the other built-in cooling functions or you can specify a custom `cool_down` function. Custom functions can be any object that responds to `#call` and accepts a single argument: the [step object](#the-step-object) for the current iteration. It should return the new temperature as a Float.

```ruby
# Use the built-in linear cool-down function (the default)
Annealing.configuration.cool_down = Annealing::Configuration::Coolers.linear

# Use the built-in exponential cool-down function
Annealing.configuration.cool_down = Annealing::Configuration::Coolers.exponential

# Use the built-in geometric cool-down function with a custom ratio (default ratio is 2)
Annealing.configuration.cool_down = Annealing::Configuration::Coolers.geometric(1.5)

# Use a custom cool down function
Annealing.configuration.cool_down = lambda do |step|
  # Reduce temperature exponentially when the temperature is above 500, then linearly
  if step.temperature > 500
    Annealing::Configuration::Coolers.exponential.call(step)
  else
    Annealing::Configuration::Coolers.linear.call(step)
  end
end
```

### `cooling_rate` and `temperature`

In the default configuration, the `cooling_rate` represents the amount by which the `temperature` will be reduced at each step, such that `temperature / cooling_rate` equals the maximum number of steps the annealer will go through in its search for the optimal solution. If a custom `cool_down` function is specified then the `cooling_rate` for the simulation will be available to that function at each step via `step.cooling_rate`, along with the current temperature via `step.temperature`. The default `cooling_rate` value is `0.0003` and the default `temperature` is `10_000`.

```ruby
Annealing.configure do |config|
  config.cooling_rate = 0.001
  config.temperature = 25_000
end
```

Generally speaking, simulations have a higher chance of finding good solutions with a high initial temperature and a low cooling rate. A high temperature gives the simulation more time to search through neighboring states for low-energy configurations, while a low cooling rate increases the probability that the simulation will select a low-energy configuration when comparing two states. For example, consider two configurations: `temperature(10_000) / cooling_rate(1)` and `temperature(100) / cooling_rate(0.01)`. Even though both provide 10,000 steps when using the default cool-down function, the latter configuration allows smaller temperature changes, which makes the annealer more likely to settle into a better final state.

### `energy_calculator`

You must specify an `energy_calculator` function before running any simulations; no default function is provided. The function can be any object that responds to `#call` and accepts a single argument: the [step object](#the-step-object) for the current iteration. Use `step.state` to access the state being measured. It should return a measurement representing the efficiency of the current state based on all of its competing factors, where a lower value represents a better configuration than a higher value.

Note: avoid calling `step.energy` inside your `energy_calculator`. It re-enters the calculator to compute the energy, which will raise a `SystemStackError`. Use `step.state` to compute the energy instead.

Note: once the temperature reaches zero, the annealer only accepts a proposed state when it has a strictly lower energy. A proposed state with an equal or higher energy is never accepted at that point.

```ruby
# A custom calculator class that takes into account hypothetical external factors
class PotentialSalesCalculator
  def initialize(initial_time_of_day)
    @initial_time_of_day = initial_time_of_day
  end

  def energy(step)
    locations = step.state
    arrival_time = @initial_time_of_day
    first_location_sales = potential_sales(locations.first, arrival_time)
    locations.each_cons(2).sum do |location1, location2|
      arrival_time += travel_time(location1, location2, arrival_time)
      distance = location1.distance(location2)
      potential_sales(location2, arrival_time) / distance
    end + first_location_sales
  end

  def potential_sales(location, time_of_day)
    habits = CustomerHabits.new(location)
    customers = habits.whos_home_at(time_of_day)
    SalesTrends.estimate(customers)
  end

  def travel_time(location1, location2, time_of_day)
    traffic = TrafficPredictor.new(location1, location2)
    traffic.travel_time(time_of_day)
  end
end

calculator = PotentialSalesCalculator.new(8)
Annealing.configuration.energy_calculator = calculator.method(:energy)
```

### `state_change`

As with `energy_calculator`, you must specify a `state_change` function in order to run any simulations; no default function is provided. The function can be any object that responds to `#call` and accepts a single argument: the [step object](#the-step-object) for the current iteration. Use `step.state` to access the current state that should be changed, and return the changed state. The `step` also gives your function access to the current `steps` count, which can be used to scale the state change over time (for example, choosing neighboring states as a function of the current iteration).

```ruby
class MyClass
  def state_change(step)
    state = step.state
    size = state.size
    swapped = state.dup
    idx_a = rand(size)
    idx_b = rand(size)
    swapped[idx_b], swapped[idx_a] = swapped[idx_a], swapped[idx_b]
    swapped
  end
end

instance = MyClass.new
Annealing.configuration.state_change = instance.method(:state_change)
```

### `termination_condition`

By default, a simulation will run until the temperature reaches 0. In some cases, you might want to specify a termination condition that will stop the annealing process as soon as some other condition is met regardless of the current temperature. To do so, you can use one of the other built-in termination condition functions or you can specify a custom one. Custom `termination_condition` functions can be any object that responds to `#call` and accepts a single argument: the [step object](#the-step-object) for the current iteration. Use `step.state`, `step.energy`, and `step.temperature` as needed. It should return a boolean value where `true` indicates the simulation should stop.

```ruby
# Use the built-in zero-temperature termination condition function
Annealing.configuration.termination_condition = Annealing::Configuration::Terminators.temp_is_zero?

# Use the built-in zero-energy termination condition function
Annealing.configuration.termination_condition = Annealing::Configuration::Terminators.energy_or_temp_is_zero?

# Use a custom termination condition function
Annealing.configuration.termination_condition = lambda do |step|
  # Stop if the energy is below 500 and the temperature is below 500, or the temperature is already 0
  step.temperature <= 0 || (step.energy <= 500 && step.temperature <= 500)
end
```

### `return_best`

If true (the default), will return the best (lowest energy) state seen during the simulation. If false, `Simulator#run` will return the final state reached when the simulation completes.

To preserve the previous final-state behavior, set `return_best: false` globally, on `Annealing::Simulator.new`, or for an individual run:

```ruby
solution = Annealing.simulate(locations,
                              energy_calculator: energy_calculator,
                              state_change: state_change,
                              return_best: false)
```

## Configuration precedence

Configuration options can be set globally using `Annealing.configuration` or `Annealing.configure`, on `Annealing::Simulator.new` for all subsequent runs of that instance, and just in time on `Annealing.simulate` and `Annealing::Simulator#run`. Later scopes override earlier ones: global < simulator instance < just in time.

### Global configuration

Global configuration options, including the defaults, have the lowest precedence. They will be used in every simulation when no overriding configuration options are present. For instance, we can rewrite the traveling salesperson example like so:

```ruby
# Set globally using block style
Annealing.configure do |config|
  config.energy_calculator = energy_calculator
end

# Or set individually
Annealing.configuration.state_change = state_change

# Now we don't need to specify them just in time
solution = Annealing.simulate(locations)
```

### Instance configuration

Instance configurations can be set on `Annealing::Simulator` instances and will apply to all subsequent simulation runs for that instance. Instance configuration options override their global configuration counterparts.

```ruby
Annealing.configure do |config|
  config.energy_calculator = energy_calculator
  config.state_change = state_change
  config.temperature = 10_000
end

simulation = Annealing::Simulator.new(temperature: 1_000)
simulation.run(locations) # Will use an initial temperature value of 1000
simulation.run(locations.shuffle) # So will this
```

### Just-in-time configuration

Just-in-time configuration options have the highest precedence and will override both global and instance options. They are only applied to the current simulation run.

```ruby
Annealing.configure do |config|
  config.cooling_rate = 0.001
  config.energy_calculator = energy_calculator
  config.state_change = state_change
  config.temperature = 10_000
end

# Will use an initial temperature of 20,000 and a cooling rate of 0.001
solution = Annealing.simulate(locations, temperature: 20_000)

# Set an instance cooling rate of 0.002
simulation = Annealing::Simulator.new(cooling_rate: 0.002)

# Will use an initial temperature of 20,000 and a cooling rate of 0.002
simulation.run(locations, temperature: 20_000)

# Will use an initial temperature of 10,000 and a cooling rate of 0.003
simulation.run(locations.shuffle, cooling_rate: 0.003)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake` to run the test suite. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `lib/annealing/version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/3zcurdia/annealing](https://github.com/3zcurdia/annealing). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/3zcurdia/annealing/blob/master/CODE_OF_CONDUCT.md).

## Code of Conduct

Everyone interacting in the Annealing project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/3zcurdia/annealing/blob/master/CODE_OF_CONDUCT.md).
