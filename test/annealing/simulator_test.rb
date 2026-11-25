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
        config.state_change = lambda(&:state)
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
        state_change: ->(step) { step.state.shuffle },
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

    def test_invalid_custom_configuration_values_raise_error_on_run
      simulator = Annealing::Simulator.new(
        calculate_energy: ->(_) { 999 },
        change_state: lambda(&:shuffle)
      )

      assert_raises(Configuration::ConfigurationError) do
        simulator.run(@collection)
      end
    end

    def test_can_specify_custom_configuration_values_on_run
      termination_condition = lambda { |step|
        step.temperature == @temperature - 10
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
      seen_temperatures = []
      termination_condition = lambda do |step|
        seen_temperatures << step.temperature
        step.temperature <= 0
      end
      final_temp = @temperature - (@cooling_rate * @total_iterations)
      state = @simulator.run(@collection,
                             termination_condition: termination_condition)

      assert_equal final_temp, state.temperature
      expected_temperatures = (0..@total_iterations).map do |step|
        @temperature - (@cooling_rate * step)
      end

      assert_equal expected_temperatures, seen_temperatures
    end

    def test_uses_cool_down_function_to_reduce_temperature_at_each_step
      seen = []
      cool_down = lambda do |step|
        seen << [step.temperature, step.cooling_rate, step.steps]
        step.temperature - 1
      end
      state = @simulator.run(@collection, cool_down: cool_down)

      assert_equal 0, state.temperature
      expected = Array.new(@total_iterations) do |step|
        [@temperature - (@cooling_rate * step), @cooling_rate, step + 1]
      end

      assert_equal expected, seen
    end

    def test_passes_run_time_configuration_to_metal
      energy_calculator = Minitest::Mock.new
      state_changer = Minitest::Mock.new
      @total_iterations.times do
        energy_calculator.expect(:call, @fake_energy) { |step| step.state == @collection }
        state_changer.expect(:call, @collection) { |step| step.state == @collection }
      end
      energy_calculator.expect(:call, @fake_energy) { |step| step.state == @collection }

      @simulator.run(@collection,
                     energy_calculator: energy_calculator,
                     state_change: state_changer)
      energy_calculator.verify
      state_changer.verify
    end

    def run_fixed_simulation(simulator: @simulator, **config_overrides)
      energies = { a: 5, b: 4, c: 1, d: 6 }
      state_sequence = %i[b c d].each
      call_count = 0

      Kernel.stub(:rand, 0.0) do
        simulator.run(:a,
                      energy_calculator: ->(step) { energies.fetch(step.state) },
                      state_change: ->(_step) { state_sequence.next },
                      cool_down: ->(step) { step.temperature - 1 },
                      termination_condition: ->(_step) { (call_count += 1) >= 4 },
                      **config_overrides)
      end
    end

    def test_returns_optimal_solution_by_default
      final_metal = run_fixed_simulation

      assert_equal :c, final_metal.state
      assert_equal 1, final_metal.energy
    end

    def test_finds_optimal_solution_when_return_best_is_true
      final_metal = run_fixed_simulation(return_best: true)

      assert_equal :c, final_metal.state
      assert_equal 1, final_metal.energy
    end

    def test_return_best_does_not_recalculate_energy
      energy_calculator = Minitest::Mock.new

      # The energy calculator is always called n+1 times. (See
      # test_passes_run_time_configuration_to_metal) We're asserting it's not called an additional
      # time when checking the energy on the final state when `return_best: true`
      (@total_iterations + 1).times do
        energy_calculator.expect(:call, @fake_energy) { |step| step.state == @collection }
      end

      state = @simulator.run(@collection, energy_calculator: energy_calculator, return_best: true)

      assert_equal @fake_energy, state.energy
      energy_calculator.verify
    end

    def test_finds_suboptimal_solution_when_not_return_best
      final_metal = run_fixed_simulation(return_best: false)

      assert_equal :d, final_metal.state
      assert_equal 6, final_metal.energy
    end

    def test_global_configuration_can_disable_return_best
      Annealing.configuration.return_best = false
      final_metal = run_fixed_simulation(simulator: Annealing::Simulator.new)

      assert_equal :d, final_metal.state
      assert_equal 6, final_metal.energy
    end

    def test_instance_configuration_can_disable_return_best
      simulator = Annealing::Simulator.new(return_best: false)
      final_metal = run_fixed_simulation(simulator: simulator)

      assert_equal :d, final_metal.state
      assert_equal 6, final_metal.energy
    end

    def test_every_custom_function_receives_a_step
      received = Hash.new { |hash, key| hash[key] = [] }
      # Wrap a function so it records the class of each argument it receives
      record = lambda do |name, function|
        lambda do |step|
          received[name] << step.class
          function.call(step)
        end
      end

      @simulator.run(@collection,
                     cool_down: record.call(:cool_down, Configuration::Coolers.linear),
                     energy_calculator: record.call(:energy_calculator, ->(_) { @fake_energy }),
                     state_change: record.call(:state_change, lambda(&:state)),
                     termination_condition: record.call(:termination_condition,
                                                        Configuration::Terminators.temp_is_zero?))

      assert_equal %i[cool_down energy_calculator state_change termination_condition], received.keys.sort
      received.each_value { |classes| assert_equal [Annealing::Step], classes.uniq }
    end

    def test_custom_functions_receive_the_documented_step_counts
      seen = { cool_down: [], state_change: [], termination_condition: [] }
      @simulator.run(@collection,
                     cool_down: lambda do |step|
                       seen[:cool_down] << step.steps
                       step.temperature - 1
                     end,
                     state_change: lambda do |step|
                       seen[:state_change] << step.steps
                       step.state
                     end,
                     termination_condition: lambda do |step|
                       seen[:termination_condition] << step.steps
                       step.temperature <= 0
                     end)

      # The termination condition and the state change see the number of
      # completed steps, while the cool down function sees the number of
      # steps including the one it is about to perform.
      assert_equal (0..@total_iterations).to_a, seen[:termination_condition]
      assert_equal (0...@total_iterations).to_a, seen[:state_change]
      assert_equal (1..@total_iterations).to_a, seen[:cool_down]
    end

    def test_run_with_a_nil_configuration_hash_uses_the_simulator_configuration
      state = @simulator.run(@collection, nil)

      assert_in_delta 0.0, state.temperature
    end

    def test_run_stops_immediately_when_the_termination_condition_is_already_met
      calls = 0
      state = @simulator.run(@collection,
                             energy_calculator: ->(_step) { calls += 1 },
                             termination_condition: ->(_step) { true })

      assert_equal @collection, state.state
      assert_equal @temperature, state.temperature
      assert_equal 1, calls
    end

    def test_run_with_return_best_computes_the_energy_when_no_steps_are_taken
      calls = 0
      state = @simulator.run(@collection,
                             energy_calculator: lambda do |_step|
                               calls += 1
                               @fake_energy
                             end,
                             termination_condition: ->(_step) { true },
                             return_best: true)

      assert_equal @collection, state.state
      assert_equal @fake_energy, state.energy
      assert_equal 1, calls
    end

    def test_instance_configuration_overrides_global_configuration
      simulator = Annealing::Simulator.new(temperature: 500)
      initial_temperatures = []
      simulator.run(@collection,
                    termination_condition: lambda do |step|
                      initial_temperatures << step.temperature
                      step.temperature <= 0
                    end)

      assert_in_delta 500.0, initial_temperatures.first
    end

    def test_just_in_time_configuration_overrides_instance_and_global_configuration
      simulator = Annealing::Simulator.new(temperature: 500)
      initial_temperatures = []
      simulator.run(@collection,
                    temperature: 100,
                    termination_condition: lambda do |step|
                      initial_temperatures << step.temperature
                      step.temperature <= 0
                    end)

      assert_in_delta 100.0, initial_temperatures.first
    end
  end
end
