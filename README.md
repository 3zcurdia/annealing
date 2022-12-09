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

In order to use this algorithm we must first define 3 things:

1. an initial object state to evaluate
2. a way to measure the energy of that state
3. and a way to change the state of the object over time

Lets use the the traveling salesperson problem as an example. First we will define a Location object with a `distance` method to measure the distance between two locations.

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

Next we need a way to calculate the total energy of traveling to each location in turn, with low energy states preferable to high energy states. Think of it as a representation of the efficiency of the trip; the further away one point is away from the next, the less efficient the trip is.

```ruby
energy_calculator = lambda do |locations|
  locations.each_cons(2).sum do |location1, location2|
    location1.distance(location2)
  end
end
```

Finally, we need a way to make small, random changes in the order of locations the salesperson will visit as we probe for an optimal route.

```ruby
state_change = lambda do |locations|
  size = locations.size
  swapped = locations.dup
  idx_a = rand(size)
  idx_b = rand(size)
  swapped[idx_b], swapped[idx_a] = swapped[idx_a], swapped[idx_b]
  swapped
end
```

Now we can run the simulation. With the default configuration it will consider ~33 million permutations of the route, so this may take several minutes to complete.

```ruby
optimal_route = Annealing.simulate(locations,
                                   energy_calculator: energy_calculator,
                                   state_change: state_change)
optimal_route.state
# => [(20,40), (40,120), (100,120), (60,200), (180,200)]
```

## Configuration options

The annealer supports a number of configuration options. See the [configuration precedence](#configuration-precedence) section below for information on the different scopes they can be applied to.

### `cool_down`

By default, the simulation will decrease the `temperature` linearly by `cooling_rate` on each step of the annealing process. In some cases you may wish to override this to use a different cooling algorithm. To do so, you can specify a custom `cool_down` function. The function can be any object that responds to `#call` and accepts three arguments: the `energy` calculation of the current object, the current `temperature` of the annealer, the `cooling_rate` for the simulation, and the number of `steps` the annealer has taken so far. It should return the new temperature as a Float.

```ruby
Annealing.configuration.cool_down = lambda do |_energy, temperature, cooling_rate, steps|
  # Reduce temperature exponentially
  temperature - (cooling_rate * (steps**2))
end
```

### `cooling_rate` and `temperature`

In the default configuration, the `cooling_rate` represents the amount by which the `temperature` will be reduced at each step, such that `temperature / cooling_rate` equals the maximum number of steps the annealer will go through in its search for the optimal solution. If a custom `cool_down` function is specified then `cooling_rate` will be passed to that function at each step along with the current temperature. The default `cooling_rate` value is `0.0003` and the default `temperature` is `10_000`.

```ruby
Annealing.configure do |config|
  config.cooling_rate = 0.001
  config.temperature = 25_000
end
```

Generally speaking, simulations have a higher chance of finding optimal solutions with a high initial temperature and a low cooling rate. A high temperature gives the simulation more time to search through neighboring states for low energy configurations, while a low cooling rate increases the probability that the simulation will select a low-energy configuration when comparing two states. For example, consider two configurations: `temperature(10000) / cooling_rate(1)` and `temperature(100) / cooling_rate(0.01)`. Even though both provide 10,000 steps when using the default cool down function, the latter configuration will allow for smaller temperature readings which is more likely to result in a more optimal final state.

### `energy_calculator`

You must specify a `energy_calculator` function before running any simulations; no default function is provided. The function can be any object that responds to `#call` and accepts a single argument: the `state` representing the current state being measured. It should return a measurement representing the efficiency of the current state based on all of its competing factors, and where a lower value represents a better configuration than a higher value.

```ruby
# A custom calculator class that takes into account hypothetical external factors
class PotentialSalesCalculator
  def initialize(initial_time_of_day)
    @initial_time_of_day = initial_time_of_day
  end

  def energy(locations)
    arrival_time = @initial_time_of_day
    first_location_sales = potential_sales(locations.first, arrival_time)
    locations.each_cons(2).sum do |location1, location2|
      arrival_time += travel_time(location1, location2, arrival_time)
      distance = location1.distance(location2)
      potential_sales(locations.first, arrival_time) / distance
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

As with `energy_calculator`, you must specify a `state_change` function in order to run any simulations; no default function is provided. The function can be any object that responds to `#call` and accepts a single argument: the `state` representing the current state that should be changed. It should return the changed state.

```ruby
class MyClass
  def state_change(state)
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

By default, a simulation will run until the temperature reaches 0. In some cases, you might want to specify a termination condition that will stop the annealing process as soon as some other condition is met regardless of the current temperature. You can define a custom `termination_condition` function, which can be any object that responds to `#call` and accepts three arguments: the current `state` of the object, the `energy` calculation of the current object, and the current `temperature` of the simulation. It should return a boolean value where `true` indicates the simulation should stop.

```ruby
Annealing.configuration.termination_condition = lambda do |_state, energy, temperature|
  # Stop early if we encounter any 0-energy state
  energy == 0 || temperature <= 0.0
end
```

## Configuration precedence

Configuration options can be set globally using `Annealing.configuration` or `Annealing.configure`, on `Annealing::Simulator.new` to be used on all subsequent runs of that instance, and just-in-time on `Annealing.simulate` and `Annealing::Simulator#run`. They are applied in reverse order of precedence.

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

Instance configurations can be set on new instances of `Annealing::Simulator` objects and will apply to all subsequent simulation runs for that instance. Instance configuration options override their global configuration counterparts.

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

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/3zcurdia/annealing](https://github.com/3zcurdia/annealing). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/3zcurdia/annealing/blob/master/CODE_OF_CONDUCT.md).

## Code of Conduct

Everyone interacting in the Annealing project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/3zcurdia/annealing/blob/master/CODE_OF_CONDUCT.md).
