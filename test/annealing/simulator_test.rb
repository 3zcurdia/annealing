# frozen_string_literal: true

require "test_helper"

module Annealing
  class SimulatorTest < Minitest::Test
    def setup
      @collection = (1..100).to_a.shuffle
      @cooling_rate = 1
      @temperature = 999
      @total_iterations = @temperature / @cooling_rate

      Annealing.configure do |config|
        config.cooling_rate = @cooling_rate
        config.energy_calculator = ->(_) { 42 }
        config.state_change = ->(state) { state }
        config.temperature = @temperature
        config.termination_condition = nil
      end

      @simulator = Annealing::Simulator.new
    end

    def test_forces_temperature_to_float
      refute_kind_of Float, @temperature
      assert_equal @temperature.to_f, @simulator.temperature
      assert_kind_of Float, @simulator.temperature
    end

    def test_forces_cooling_rate_to_negative_float
      refute_kind_of Float, @cooling_rate
      assert_equal @cooling_rate.to_f * -1, @simulator.cooling_rate
      assert_kind_of Float, @simulator.cooling_rate
    end

    def test_raises_an_error_if_the_temperature_is_negative
      assert_raises(ArgumentError, "Invalid initial temperature") do
        Annealing::Simulator.new(temperature: @temperature * -1)
      end
    end

    def test_uses_the_global_energy_calculator_and_state_change_method
      global_energy_calculator = MiniTest::Mock.new
      global_state_changer = MiniTest::Mock.new
      (@total_iterations + 1).times do
        global_energy_calculator.expect(:call, 42, [@collection])
        global_state_changer.expect(:call, @collection, [@collection])
      end
      global_energy_calculator.expect(:call, 42, [@collection])

      Annealing.configure do |config|
        config.energy_calculator = global_energy_calculator
        config.state_change = global_state_changer
      end

      Annealing::Simulator.new.run(@collection)
      global_energy_calculator.verify
      global_state_changer.verify
    end

    def test_can_override_the_global_energy_calculator_and_state_change_method
      local_energy_calculator = MiniTest::Mock.new
      local_state_changer = MiniTest::Mock.new
      (@total_iterations + 1).times do
        local_energy_calculator.expect(:call, 42, [@collection])
        local_state_changer.expect(:call, @collection, [@collection])
      end
      local_energy_calculator.expect(:call, 42, [@collection])

      Annealing.configure do |config|
        config.energy_calculator = MiniTest::Mock.new
        config.state_change = MiniTest::Mock.new
      end

      Annealing::Simulator.new.run(@collection,
                                   energy_calculator: local_energy_calculator,
                                   state_change: local_state_changer)
      local_energy_calculator.verify
      local_state_changer.verify
    end

    def test_uses_the_global_termination_condition_function_if_set
      global_termination_condition = MiniTest::Mock.new
      (@total_iterations + 1).times do |i|
        current_temp = @temperature - (@cooling_rate * i)
        global_termination_condition.expect(:call, false,
                                            [@collection, 42, current_temp])
      end

      Annealing.configure do |config|
        config.termination_condition = global_termination_condition
      end

      Annealing::Simulator.new.run(@collection)
      global_termination_condition.verify
    end

    def test_can_override_the_global_termination_condition
      local_termination_condition = MiniTest::Mock.new
      (@total_iterations + 1).times do |i|
        current_temp = @temperature - (@cooling_rate * i)
        local_termination_condition.expect(:call, false,
                                           [@collection, 42, current_temp])
      end

      Annealing.configure do |config|
        config.termination_condition = MiniTest::Mock.new
      end

      simulator = Annealing::Simulator.new
      simulator.run(@collection,
                    termination_condition: local_termination_condition)
      local_termination_condition.verify
    end

    def test_returns_early_if_termination_condition_is_met
      global_energy_calculator = MiniTest::Mock.new
      @total_iterations = 1 # We'll exit after the temp drops 1 step
      (@total_iterations + 1).times do
        global_energy_calculator.expect(:call, 42, [@collection])
      end

      global_termination_condition = lambda do |_state, _energy, temp|
        temp == @temperature - 1
      end

      Annealing.configure do |config|
        config.energy_calculator = global_energy_calculator
        config.termination_condition = global_termination_condition
      end

      Annealing::Simulator.new.run(@collection)
      global_energy_calculator.verify
    end
  end
end
