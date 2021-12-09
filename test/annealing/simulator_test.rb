# frozen_string_literal: true

require 'test_helper'

describe Annealing::Simulator do
  let(:simulator) do
    Annealing::Simulator.new(temperature: 10_000, cooling_rate: 0.01)
  end
  let(:locations) do
    [
      Location.new(3, 3),
      Location.new(1, 1),
      Location.new(4, 4),
      Location.new(5, 5),
      Location.new(2, 2)
    ]
  end
  let(:default_energy_calculator) do
    lambda do |locations|
      locations.each_cons(2).sum do |location1, location2|
        location1.distance(location2)
      end
    end
  end
  let(:default_state_change) do
    lambda do |locations|
      size = locations.size
      swapped = locations.dup
      idx_a = rand(size)
      idx_b = rand(size)
      swapped[idx_b], swapped[idx_a] = swapped[idx_a], swapped[idx_b]
      swapped
    end
  end

  before do
    Annealing.configure do |config|
      config.energy_calculator = default_energy_calculator
      config.state_change = default_state_change
    end
  end

  after do
    Annealing.configuration.reset
  end

  it 'uses the global energy calculator and state change method' do
    initial_energy = default_energy_calculator.call(locations)
    assert_equal 46, initial_energy
    simulation = simulator.run(locations)
    assert_operator simulation.energy, :<, initial_energy
  end

  it 'can override the global energy calculator and state change method' do
    initial_state = rand * 16
    local_energy_calculator = ->(state) { (state**2) - 16 }
    local_state_change = ->(state) { state + (rand - 0.5) }
    initial_energy = local_energy_calculator.call(initial_state)
    simulation = simulator.run(initial_state,
                               energy_calculator: local_energy_calculator,
                               state_change: local_state_change)
    assert_operator simulation.energy, :<, initial_energy
  end
end
