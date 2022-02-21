# frozen_string_literal: true

require "test_helper"

module Annealing
  class SimulatorTest < Minitest::Test
    def setup
      @collection = (1..100).to_a
      @cooling_rate = 1
      @temperature = 999
      @total_iterations = @temperature / @cooling_rate

      # Set global defaults
      Annealing.configure do |config|
        config.cooling_rate = @cooling_rate
        config.energy_calculator = ->(_) { 42 }
        config.state_change = ->(state) { state }
        config.temperature = @temperature
      end

      @simulator = Annealing::Simulator.new
    end

    def test_run_raises_an_error_if_the_temperature_is_negative
      assert_raises(ArgumentError, "Invalid initial temperature") do
        @simulator.run(@collection, temperature: @temperature * -1)
      end
    end

    def test_run_raises_an_error_if_the_cooling_rate_is_negative
      assert_raises(ArgumentError, "Invalid initial cooling rate") do
        @simulator.run(@collection, cooling_rate: @cooling_rate * -1)
      end
    end

    def test_run_raises_an_error_if_cool_down_funtion_not_specified
      Annealing.configuration.cool_down = nil
      assert_raises(ArgumentError, "Missing cool down function") do
        simulator = Annealing::Simulator.new
        simulator.run(@collection)
      end
    end

    def test_run_raises_an_error_if_termination_condition_not_specified
      Annealing.configuration.termination_condition = nil
      assert_raises(ArgumentError, "Missing termination condition function") do
        simulator = Annealing::Simulator.new
        simulator.run(@collection)
      end
    end

    def test_forces_global_cooling_rate_configs_to_float
      Annealing.configuration.cooling_rate = 99
      simulator = Annealing::Simulator.new
      assert_kind_of Float, simulator.send(:cooling_rate)
      assert_in_delta 99.0, simulator.send(:cooling_rate)
    end

    def test_forces_instance_cooling_rate_configs_to_float
      simulator = Annealing::Simulator.new(cooling_rate: 88)
      assert_kind_of Float, simulator.send(:cooling_rate)
      assert_in_delta 88.0, simulator.send(:cooling_rate)
    end

    def test_forces_local_cooling_rate_configs_to_float
      @simulator.with_configuration_overrides(cooling_rate: 77) do
        assert_kind_of Float, @simulator.send(:cooling_rate)
        assert_in_delta 77.0, @simulator.send(:cooling_rate)
      end
    end

    def test_forces_global_temperature_to_float
      Annealing.configuration.temperature = 99
      simulator = Annealing::Simulator.new
      assert_kind_of Float, simulator.send(:temperature)
      assert_in_delta 99.0, simulator.send(:temperature)
    end

    def test_forces_instance_temperature_to_float
      simulator = Annealing::Simulator.new(temperature: 88)
      assert_kind_of Float, simulator.send(:temperature)
      assert_in_delta 88.0, simulator.send(:temperature)
    end

    def test_forces_local_temperature_to_float
      @simulator.with_configuration_overrides(temperature: 77) do
        assert_kind_of Float, @simulator.send(:temperature)
        assert_in_delta 77.0, @simulator.send(:temperature)
      end
    end

    def test_runs_simulation_until_temperature_reaches_zero_by_default
      state = @simulator.run(@collection)
      assert_equal 0, state.temperature
    end

    def test_returns_early_if_global_termination_condition_is_met
      termination_condition = lambda do |_state, _energy, temperature|
        temperature == @temperature - 10
      end

      state = @simulator.run(@collection,
                             termination_condition: termination_condition)
      assert_equal @temperature - 10, state.temperature
    end

    def test_uses_energy_calculator_and_state_change_functions
      energy_calculator = MiniTest::Mock.new
      state_changer = MiniTest::Mock.new
      @total_iterations.times do
        energy_calculator.expect(:call, 42, [@collection])
        state_changer.expect(:call, @collection, [@collection])
      end
      energy_calculator.expect(:call, 42, [@collection])

      @simulator.run(@collection,
                     energy_calculator: energy_calculator,
                     state_change: state_changer)
      energy_calculator.verify
      state_changer.verify
    end

    def test_uses_cool_down_function
      cool_down = lambda do |_energy, temperature, cooling_rate, steps|
        # Reduce temperature exponentially
        temperature - (cooling_rate * (steps**2))
      end

      metal = Annealing::Metal.new(@collection, @temperature)
      metal_klass = MiniTest::Mock.new
      last_temp = @temperature.to_f
      15.times do |i|
        current_temp = last_temp - (@cooling_rate * (i**2))
        metal_klass.expect(:call, metal) do |state, temperature, _options|
          state == @collection && temperature == current_temp
        end
        last_temp = current_temp
      end

      Annealing::Metal.stub(:new, metal_klass) do
        metal.stub(:better_than?, false) do # Always return self
          final_state = @simulator.run(@collection, cool_down: cool_down)
          metal_klass.verify
          assert_in_delta(-16.0, final_state.temperature)
        end
      end
    end
  end
end
