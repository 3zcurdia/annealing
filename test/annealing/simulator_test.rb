# frozen_string_literal: true

require 'test_helper'

module Annealing
  class SimulatorTest < Minitest::Test
    def setup
      @locations = [
        Location.new(3, 3),
        Location.new(1, 1),
        Location.new(4, 4),
        Location.new(5, 5),
        Location.new(2, 2)
      ]

      @energy_calculator = -> (locations) do
        locations.each_cons(2).sum do |location1, location2|
          location1.distance(location2)
        end
      end

      Annealing.configure do |config|
        config.energy_calculator = @energy_calculator
        config.state_change = -> (locations) do
          size = locations.size
          swapped = locations.dup
          idx_a = rand(size)
          idx_b = rand(size)
          swapped[idx_b], swapped[idx_a] = swapped[idx_a], swapped[idx_b]
          swapped
        end
      end

      @simulator = Simulator.new(temperature: 10_000, cooling_rate: 0.01)
    end

    def teardown
      Annealing.configuration.reset
    end

    def test_run
      initial_energy = @energy_calculator.call(@locations)
      assert_equal 46, initial_energy
      simulation = @simulator.run(@locations)
      assert_operator simulation.energy, :<, initial_energy
    end

    def test_run_with_calc_and_move_override
      initial_state = rand * 16
      energy_calculator = -> (state) { state * state - 16 }
      state_change = -> (state) { state + (rand - 0.5) }
      initial_energy = energy_calculator.call(initial_state)
      simulation = @simulator.run(initial_state,
                                  energy_calculator: energy_calculator,
                                  state_change: state_change)
      assert_operator simulation.energy, :<, initial_energy
    end
  end
end
