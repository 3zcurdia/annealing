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

    def test_run
      simulation = simulator.run(collection)
      assert simulation.delta < 355
    end
  end
end
