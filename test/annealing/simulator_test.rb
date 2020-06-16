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
      Simulator.new(temperature: 10_000, cooling_rate: 0.003)
    end

    def test_acceptance_one
      assert_equal 1.0, simulator.send(:acceptance, 1, 1, 10_000)
    end

    def test_acceptance_lower_new_delta
      assert_equal 1.0, simulator.send(:acceptance, 2, 1, 1)
    end

    def test_acceptance_negative
      assert_equal Math::E, simulator.send(:acceptance, 1, 2, -1)
    end

    def test_run
      simulation = simulator.run(collection)
      assert simulation.delta < 400
    end
  end
end
