# frozen_string_literal: true

require 'test_helper'
require 'debug'

module Annealing
  class SimulatorTest < Minitest::Test
    def setup
      @collection = (1..100).to_a.shuffle

      Annealing.configure do |config|
        config.energy_calculator = lambda do |collection|
          collection.each_with_index.sum { |n, i| Math.exp(i) * n }
        end
        config.state_change = ->(collection) { collection.shuffle }
      end
    end

    def test_forces_temperature_to_float
      custom_temperature = 9_999
      refute_kind_of Float, custom_temperature
      simulator = Annealing::Simulator.new(temperature: custom_temperature)
      assert_kind_of Float, simulator.temperature
    end

    def test_forces_cooling_rate_to_float
      custom_cooling_rate = 1
      refute_kind_of Float, custom_cooling_rate
      simulator = Annealing::Simulator.new(cooling_rate: custom_cooling_rate)
      assert_kind_of Float, simulator.cooling_rate
    end

    def test_raises_an_error_if_the_temperature_is_negative
      assert_raises(ArgumentError, 'Invalid initial temperature') do
        Annealing::Simulator.new(temperature: -9_999)
      end
    end

    def test_uses_the_global_energy_calculator_and_state_change_method
      custom_temperature = 1000
      custom_cooling_rate = 1
      total_iterations = custom_temperature / custom_cooling_rate
      global_energy_calculator = MiniTest::Mock.new
      global_state_changer = MiniTest::Mock.new
      (total_iterations + 1).times do
        global_energy_calculator.expect(:call, 42, [@collection])
        global_state_changer.expect(:call, @collection, [@collection])
      end
      global_energy_calculator.expect(:call, 42, [@collection])

      Annealing.configure do |config|
        config.temperature = custom_temperature
        config.cooling_rate = custom_cooling_rate
        config.energy_calculator = global_energy_calculator
        config.state_change = global_state_changer
      end

      Annealing::Simulator.new.run(@collection)
      global_energy_calculator.verify
      global_state_changer.verify
    end

    def test_can_override_the_global_energy_calculator_and_state_change_method
      custom_temperature = 1000
      custom_cooling_rate = 1
      total_iterations = custom_temperature / custom_cooling_rate
      local_energy_calculator = MiniTest::Mock.new
      local_state_changer = MiniTest::Mock.new
      (total_iterations + 1).times do
        local_energy_calculator.expect(:call, 42, [@collection])
        local_state_changer.expect(:call, @collection, [@collection])
      end
      local_energy_calculator.expect(:call, 42, [@collection])

      Annealing.configure do |config|
        config.temperature = custom_temperature
        config.cooling_rate = custom_cooling_rate
        config.energy_calculator = MiniTest::Mock.new
        config.state_change = MiniTest::Mock.new
      end

      Annealing::Simulator.new.run(@collection,
                                   energy_calculator: local_energy_calculator,
                                   state_change: local_state_changer)
      local_energy_calculator.verify
      local_state_changer.verify
    end
  end
end
