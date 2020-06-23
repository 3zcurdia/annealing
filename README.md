# Annealing
[![Gem Version](https://badge.fury.io/rb/annealing.svg)](https://badge.fury.io/rb/annealing)

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

To use this gem, you must have an object that implements a `distance` method or a lambda function where you calculate the total energy of an enumerable object.

Lets solve the traveling salesman, for that we will need an object with a distance method
to mesure the distance between two locations.

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

Now we can create an array of the locations

```ruby
locations = [
  Location.new(60, 200),
  Location.new(180, 200),
  Location.new(40, 120),
  Location.new(100, 120),
  Location.new(20, 40)
]
```

Now we can just pass the locations argumen.

```ruby
puts Annealing.simulate(locations)
[(20,40), (40,120), (100,120), (60,200), (180,200)]
```

This will run the simulation with the default parameters and it could take a while to finish.
But if you want to iterate with other parameters you can send the parameters `temperature` and `cooling_rate`.

```ruby
simulator = Annealing::Simulator.new(temperature: 10_000, cooling_rate: 0.5)
solution = simulator.run(locations)
solution.energy
351.901234
solution.collection
[(20,40), (40,120), (100,120), (60,200), (180,200)]
```

You can also configure the default parameters

```ruby
Annealing.configure do |c|
  c.temperature  = 10_000.0
  c.cooling_rate = 0.003
end
```

### Custom total energy calculator

You can set a lambda function to customize the total energy in a collection by setting in the default parameters

```ruby
Annealing.configure do |c|
  c.total_energy_calculator = lambda do |enumerable|
    enumerable.each_cons(2).sum { |a, b| a.distance(b) }
  end
end
```

or in the simulator as a parameter

```ruby
calc = lambda do |enumerable|
  enumerable.each_cons(2).sum { |a, b| a.distance(b) }
end
solution = simulator.run(locations, calc).collection
[(20,40), (40,120), (100,120), (60,200), (180,200)]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/3zcurdia/annealing. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/3zcurdia/annealing/blob/master/CODE_OF_CONDUCT.md).


## Code of Conduct

Everyone interacting in the Annealing project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/3zcurdia/annealing/blob/master/CODE_OF_CONDUCT.md).
