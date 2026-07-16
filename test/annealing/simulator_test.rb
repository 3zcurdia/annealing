# frozen_string_literal: true

require "test_helper"

module Annealing
  class SimulatorTest < Minitest::Test
    def setup
      @collection = (1..100).to_a
      @cooling_rate = 1.0
      @temperature = 999.0
      @total_iterations = (@temperature / @cooling_rate).to_i

      # Set global defaults
      @fake_energy = 42
      @global_config = Annealing.configure do |config|
        config.cooling_rate = @cooling_rate
        config.energy_calculator = ->(_) { @fake_energy }
        config.state_change = ->(state) { state }
        config.temperature = @temperature
      end

      @simulator = Annealing::Simulator.new
    end

    def test_inherits_global_configuration_by_default
      simulator_config = @simulator.configuration

      assert_equal @global_config.cool_down,
                   simulator_config.cool_down
      assert_equal @global_config.cooling_rate,
                   simulator_config.cooling_rate
      assert_equal @global_config.energy_calculator,
                   simulator_config.energy_calculator
      assert_equal @global_config.state_change,
                   simulator_config.state_change
      assert_equal @global_config.temperature,
                   simulator_config.temperature
      assert_equal @global_config.termination_condition,
                   simulator_config.termination_condition
    end

    def test_can_specify_custom_configuration_values_on_initialization
      simulator_config = Annealing::Simulator.new(
        cooling_rate: 0.1,
        energy_calculator: ->(_) { 999 },
        state_change: lambda(&:shuffle),
        temperature: 99
      ).configuration

      refute_equal @global_config.cooling_rate,
                   simulator_config.cooling_rate
      refute_equal @global_config.energy_calculator,
                   simulator_config.energy_calculator
      refute_equal @global_config.state_change,
                   simulator_config.state_change
      refute_equal @global_config.temperature,
                   simulator_config.temperature
    end

    def test_can_specify_custom_configuration_values_on_run
      termination_condition = lambda { |_state, _energy, temperature|
        temperature == @temperature - 10
      }
      state = @simulator.run(@collection,
                             termination_condition: termination_condition)

      assert_equal @temperature - 10, state.temperature
    end

    def test_run_raises_an_error_if_configuration_not_valid
      simulator_config = @simulator.configuration
      simulator_config.cool_down = nil
      assert_raises(Annealing::Configuration::ConfigurationError) do
        @simulator.run(@collection)
      end
    end

    def test_runs_simulation_until_termination_condition_is_met
      termination_condition = Minitest::Mock.new
      @total_iterations.times do |step|
        current_temp = @temperature - (@cooling_rate * step)
        termination_condition.expect(:call, false, [@collection,
                                                    @fake_energy,
                                                    current_temp])
      end
      final_temp = @temperature - (@cooling_rate * @total_iterations)
      termination_condition.expect(:call, true, [@collection,
                                                 @fake_energy,
                                                 final_temp])
      state = @simulator.run(@collection,
                             termination_condition: termination_condition)

      assert_equal final_temp, state.temperature
      termination_condition.verify
    end

    def test_uses_cool_down_function_to_reduce_temperature_at_each_step
      cool_down = Minitest::Mock.new
      @total_iterations.times do |step|
        current_temp = @temperature - (@cooling_rate * step)
        new_temp = @temperature - ((@cooling_rate * step) + 1)
        cool_down.expect(:call, new_temp, [@fake_energy, current_temp,
                                           @cooling_rate, step + 1])
      end
      state = @simulator.run(@collection, cool_down: cool_down)

      assert_equal 0, state.temperature
      cool_down.verify
    end

    def test_passes_run_time_configuration_to_metal
      energy_calculator = Minitest::Mock.new
      state_changer = Minitest::Mock.new
      @total_iterations.times do
        energy_calculator.expect(:call, @fake_energy, [@collection])
        state_changer.expect(:call, @collection, [@collection])
      end
      energy_calculator.expect(:call, @fake_energy, [@collection])

      @simulator.run(@collection,
                     energy_calculator: energy_calculator,
                     state_change: state_changer)
      energy_calculator.verify
      state_changer.verify
    end

    def run_fixed_simulation(return_best:)
      energies = { a: 5, b: 4, c: 1, d: 6 }
      state_sequence = %i[b c d].each
      call_count = 0

      Kernel.stub(:rand, 0.0) do
        @simulator.run(:a,
                       energy_calculator: ->(s) { energies.fetch(s) },
                       state_change: ->(_) { state_sequence.next },
                       cool_down: ->(_energy, temp, _rate, _step) { temp - 1 },
                       termination_condition: ->(_s, _e, _t) { (call_count += 1) >= 4 },
                       return_best: return_best)
      end
    end

    def test_finds_optimal_solution_when_return_best
      final_metal = run_fixed_simulation(return_best: true)

      assert_equal :c, final_metal.state
      assert_equal 1, final_metal.energy
    end

    def test_finds_suboptimal_solution_when_not_return_best
      final_metal = run_fixed_simulation(return_best: false)

      assert_equal :d, final_metal.state
      assert_equal 6, final_metal.energy
      refute_equal :c, final_metal.state
    end
  end
end
