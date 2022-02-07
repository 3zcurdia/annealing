# Annealing
[![Gem Version](https://badge.fury.io/rb/annealing.svg)](https://badge.fury.io/rb/annealing)
[![Ruby](https://github.com/3zcurdia/annealing/actions/workflows/ruby.yml/badge.svg)](https://github.com/3zcurdia/annealing/actions/workflows/ruby.yml)

Find the optimal solution in a complex problem through a simulated annealing implementation for enumerable objects. Where the energy of each object can be measured by a distance method between two elements or a lambda function where the total energy is calculated in the objects.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'annealing'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install annealing

## Usage

To use this gem, you must provide a lambda function to calculate the total energy of an object, and a way to change the state of the object to a neighboring state.

Lets solve the traveling salesman problem. First we will need an object with a distance method to measure the distance between two locations.

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

Next we need a way to calculate the total energy of traveling to each location in turn. Think of it as a representation of the efficiency of the trip; the further away one point is away from the next, the less efficient the trip is.

```ruby
energy_calculator = lambda do |locations|
  locations.each_cons(2).sum do |location1, location2|
    location1.distance(location2)
  end
end
```

Finally, we need a way to make small, random changes the order of the locations the salesperson will visit as we probe for the most efficient route.

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

Now we can just pass the locations argument as the initial state and let the annealer search for the most efficient route. This will run the simulation with the default temperature and cooling rate, which could take a while to finish.

```ruby
simulator = Annealing::Simulator.new
solution = simulator.run(locations,
                         energy_calculator: energy_calculator,
                         state_change: state_change)
solution.state
# => [(20,40), (40,120), (100,120), (60,200), (180,200)]
```

### Using custom temperature and cooling settings

If you want to iterate with other parameters you can send the parameters `temperature` and `cooling_rate`.

```ruby
simulator = Annealing::Simulator.new(temperature: 10_000, cooling_rate: 0.5)
solution = simulator.run(locations, energy_calculator: energy_calculator,
                                    state_change: state_change)
solution.state
# => [(20,40), (40,120), (100,120), (60,200), (180,200)]
```

## Configuration

You can set default parameters that will be used in every simulation. For instance, we can rewrite the previous example like so:

```ruby
Annealing.configure do |c|
  c.temperature  = 10_000
  c.cooling_rate = 0.5
  c.energy_calculator = energy_calculator
  c.state_change = state_change
end

solution = Annealing.simulate(locations)
```

Note that `energy_calculator` and `state_change` can be any object that responds to `#call` and accepts a single argument which is the current state being measured or moved. This allows for lots of flexibility. For instance, you could use a custom calculator class that takes into account some other external factor:

```ruby
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
simulator = Annealing::Simulator.new
solution = simulator.run(locations, energy_calculator: calculator.method(:energy))
```

### Setting a simulation termination condition

Typically, annealing simulators are tasked with finding "close enough" solutions to complex problems by continuously comparing new permutations of an object against one other as the temperature slowly drops to 0 and then returning the lowest energy configuration it found. However, sometimes "close enough" can be determined by other factors as well. For this reason, you might specify a termination condition that will stop the annealing process as soon as the "good enough" condition is met regardless of the current temperature.

Like `energy_calculator` and `state_change`, the `termination_condition` can be any object that responds to `#call` and it can be set globally or per simulation. It should accept three arguments: the current `state` of the object, the `energy` calculation of the current object, and the current `temperature` of the annealer.

```ruby
# Stop as soon as we find any 0-energy state
termination_condition = lambda do |state, energy, temperature|
  energy == 0
end

simulator = Annealing::Simulator.new
solution = simulator.run(some_collection, termination_condition: termination_condition)
solution.state
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake` to run the test suite. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/3zcurdia/annealing. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/3zcurdia/annealing/blob/master/CODE_OF_CONDUCT.md).

## Code of Conduct

Everyone interacting in the Annealing project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/3zcurdia/annealing/blob/master/CODE_OF_CONDUCT.md).
