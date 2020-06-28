# frozen_string_literal: true

require 'test_helper'

module Annealing
  class SimulatorTest < Minitest::Test
    def collection
      [
        Location.new(60, 200),
        Location.new(180, 200),
        Location.new(40, 120),
        Location.new(100, 120),
        Location.new(20, 40)
      ]
    end

    def simulator
      Simulator.new(temperature: 10_000, cooling_rate: 0.01)
    end

    def test_run
      simulation = simulator.run(collection)
      assert simulation.energy < 33_000
    end

    def calc_lambda
      ->(c) { c.each_with_index.sum { |x, i| 2**(x - i) } }
    end

    def test_run_with_custom_calc
      arr = (1..10).to_a.shuffle
      simulation = simulator.run(arr, calc_lambda)
      assert simulation.energy <= 22
    end
  end
end
