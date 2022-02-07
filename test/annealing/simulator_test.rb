# frozen_string_literal: true

require "test_helper"

module Annealing
  class SimulatorTest < Minitest::Test
    def setup
      @collection = (1..100).to_a
      @cooling_rate = 1
      @temperature = 999
      @total_iterations = @temperature / @cooling_rate

      Annealing.configure do |config|
        config.cooling_rate = @cooling_rate
        config.energy_calculator = ->(_) { 42 }
        config.state_change = ->(state) { state }
        config.temperature = @temperature
      end

      @simulator = Annealing::Simulator.new
    end

    def test_forces_temperature_to_float
      refute_kind_of Float, @temperature
      assert_equal @temperature.to_f, @simulator.temperature
      assert_kind_of Float, @simulator.temperature
    end

    def test_forces_cooling_rate_to_float
      refute_kind_of Float, @cooling_rate
      assert_equal @cooling_rate.to_f, @simulator.cooling_rate
      assert_kind_of Float, @simulator.cooling_rate
    end

    def test_raises_an_error_if_the_temperature_is_negative
      assert_raises(ArgumentError, "Invalid initial temperature") do
        Annealing::Simulator.new(temperature: @temperature * -1)
      end
    end

    def test_raises_an_error_if_the_cooling_rate_is_negative
      assert_raises(ArgumentError, "Invalid initial cooling rate") do
        Annealing::Simulator.new(cooling_rate: @cooling_rate * -1)
      end
    end

    def test_raises_an_error_if_cool_down_funtion_not_specified
      Annealing.configuration.cool_down = nil
      assert_raises(ArgumentError, 'Missing cool down function') do
        simulator = Annealing::Simulator.new
        simulator.run(@collection)
      end
    end

    def test_raises_an_error_if_termination_condition_not_specified
      Annealing.configuration.termination_condition = nil
      assert_raises(ArgumentError, 'Missing termination condition function') do
        simulator = Annealing::Simulator.new
        simulator.run(@collection)
      end
    end

    def test_runs_simulation_until_temperature_reaches_zero_by_default
      state = @simulator.run(@collection)
      assert_equal 0, state.temperature
    end

    def test_returns_early_if_global_termination_condition_is_met
      Annealing.configure do |config|
        # Exit after the temp drops 10 steps
        config.termination_condition = lambda do |_state, _energy, temperature|
          temperature == @temperature - 10
        end
      end

      simulator = Annealing::Simulator.new
      state = simulator.run(@collection)
      assert_equal @temperature - 10, state.temperature
    end

    def test_can_override_the_global_termination_condition
      Annealing.configure do |config|
        config.termination_condition = lambda do |_state, _energy, temperature|
          temperature == @temperature - 10
        end
      end

      # Exit after the temp drops 20 steps
      local_termination_condition = lambda do |_state, _energy, temperature|
        temperature == @temperature - 20
      end

      simulator = Annealing::Simulator.new
      final_state = simulator.run(
        @collection,
        termination_condition: local_termination_condition
      )
      assert_equal @temperature - 20, final_state.temperature
    end

    def test_uses_global_energy_calculator_and_state_change_functions_by_default
      global_energy_calculator = MiniTest::Mock.new
      global_state_changer = MiniTest::Mock.new
      @total_iterations.times do
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

    def test_can_override_global_energy_calculator_and_state_change_functions
      local_energy_calculator = MiniTest::Mock.new
      local_state_changer = MiniTest::Mock.new
      @total_iterations.times do
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

    def test_uses_linear_cool_down_by_default
      metal = Annealing::Metal.new(@collection, @temperature)
      metal_klass = MiniTest::Mock.new
      metal_klass.expect(:call, metal) do |state, temperature, _options|
        state == @collection && temperature == @temperature
      end
      @total_iterations.times do |i|
        current_temp = @temperature - (@cooling_rate * i) - 1
        metal_klass.expect(:call, metal) do |state, temperature, _options|
          state == @collection && temperature == current_temp
        end
      end

      Annealing::Metal.stub(:new, metal_klass) do
        metal.stub(:better_than?, false) do # Always return self
          final_state = @simulator.run(@collection)
          metal_klass.verify
          assert_equal 0, final_state.temperature
        end
      end
    end

    def test_can_override_global_cool_down_function
      # Reduce temperature exponentially
      local_cool_down = lambda do |_energy, temperature, cooling_rate, steps|
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
          final_state = @simulator.run(@collection, cool_down: local_cool_down)
          metal_klass.verify
          assert_in_delta(-16.0, final_state.temperature)
        end
      end
    end
  end
end
