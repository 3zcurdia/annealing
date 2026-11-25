# frozen_string_literal: true

require "test_helper"

module Annealing
  class ConfigurationTest < Minitest::Test
    def setup
      @subject = Annealing::Configuration
      @valid_configuration_options = {
        energy_calculator: ->(*_args) {},
        state_change: ->(*_args) {}
      }
      @valid_configuration = @subject.new(**@valid_configuration_options)
      @error_class = @subject::ConfigurationError
    end

    def test_sets_a_default_linear_cool_down_function
      cool_down = @subject.new.cool_down

      assert_respond_to cool_down, :call
      assert_equal 1, cool_down.call(step_with(temperature: 2))
    end

    def test_sets_a_default_cooling_rate
      assert_in_delta @subject::DEFAULT_COOLING_RATE,
                      @subject.new.cooling_rate
    end

    def test_sets_a_default_initial_temperature
      assert_in_delta @subject::DEFAULT_INITIAL_TEMPERATURE,
                      @subject.new.temperature
    end

    def test_sets_a_default_termination_condition_function
      termination_condition = @subject.new.termination_condition

      assert_respond_to termination_condition, :call
      refute termination_condition.call(step_with(temperature: 1))
      assert termination_condition.call(step_with(temperature: 0))
      assert termination_condition.call(step_with(temperature: -1))
    end

    def test_does_not_set_a_default_energy_calculator_function
      assert_nil @subject.new.energy_calculator
    end

    def test_does_not_set_a_default_state_change_function
      assert_nil @subject.new.state_change
    end

    def test_merge_creates_new_configuration_from_config_hash
      new_temperature = 3000
      new_config = @valid_configuration.merge(temperature: new_temperature)

      refute_same @valid_configuration, new_config
      assert_equal new_config.temperature, new_temperature
      refute_equal @valid_configuration.temperature, new_config.temperature
    end

    def test_merge_inherits_current_configuration_attributes
      new_config = @valid_configuration.merge({})

      assert_equal @valid_configuration.cool_down,
                   new_config.cool_down
      assert_equal @valid_configuration.cooling_rate,
                   new_config.cooling_rate
      assert_equal @valid_configuration.energy_calculator,
                   new_config.energy_calculator
      assert_equal @valid_configuration.state_change,
                   new_config.state_change
      assert_equal @valid_configuration.temperature,
                   new_config.temperature
      assert_equal @valid_configuration.termination_condition,
                   new_config.termination_condition
    end

    def test_merge_changing_new_configuration_does_not_affect_original
      new_config = @valid_configuration.merge({})
      new_config.cooling_rate += 0.005
      new_config.temperature -= 100

      refute_equal @valid_configuration.cooling_rate,
                   new_config.cooling_rate
      refute_equal @valid_configuration.temperature,
                   new_config.temperature
    end

    def test_merge_raises_error_unless_options_is_hash
      error = assert_raises(@error_class) do
        @valid_configuration.merge(:foo)
      end
      assert_equal "Merge options must be a hash", error.message
    end

    def test_validates_temperature_is_non_negative_float
      @valid_configuration.validate!
      @valid_configuration.temperature = -100
      error = assert_raises(@error_class) do
        @valid_configuration.validate!
      end
      assert_equal "Initial temperature must be a non-negative float", error.message
    end

    def test_validates_cooling_rate_is_positive_float
      @valid_configuration.validate!
      @valid_configuration.cooling_rate = -0.005
      error = assert_raises(@error_class) do
        @valid_configuration.validate!
      end
      assert_equal "Cooling rate must be a positive float", error.message
    end

    def test_validates_cool_down_funtion_is_callable
      @valid_configuration.validate!
      @valid_configuration.cool_down = nil
      error = assert_raises(@error_class) do
        @valid_configuration.validate!
      end
      assert_equal "Missing cool down function", error.message
    end

    def test_validates_energy_calculator_is_callable
      @valid_configuration.validate!
      @valid_configuration.energy_calculator = nil
      error = assert_raises(@error_class) do
        @valid_configuration.validate!
      end
      assert_equal "Missing energy calculator function", error.message
    end

    def test_validates_state_change_is_callable
      @valid_configuration.validate!
      @valid_configuration.state_change = nil
      error = assert_raises(@error_class) do
        @valid_configuration.validate!
      end
      assert_equal "Missing state change function", error.message
    end

    def test_validates_termination_condition_is_callable
      @valid_configuration.validate!
      @valid_configuration.termination_condition = nil
      error = assert_raises(@error_class) do
        @valid_configuration.validate!
      end
      assert_equal "Missing termination condition function", error.message
    end

    def test_validates_return_best
      @valid_configuration.validate!
      @valid_configuration.return_best = nil
      error = assert_raises(@error_class) do
        @valid_configuration.validate!
      end
      assert_equal "Return best must be either true or false", error.message
    end

    def test_validates_no_unknown_options
      @invalid_configuration = @subject.new(@valid_configuration_options.merge(
                                              calculate_energy: ->(*_args) {},
                                              change_state: ->(*_args) {}
                                            ))

      error = assert_raises(@error_class) do
        @invalid_configuration.validate!
      end
      assert_equal "Unrecognized configuration options: calculate_energy, change_state", error.message
    end

    def test_merge_inherits_bad_config_keys_from_base
      base_configuration = @subject.new(@valid_configuration_options.merge(bad: :key))
      new_config = base_configuration.merge({})

      error = assert_raises(@error_class) do
        new_config.validate!
      end
      assert_equal "Unrecognized configuration options: bad", error.message
    end

    private

    # Build a real Annealing::Step for a given temperature, the way the
    # simulator does.
    def step_with(temperature:, cooling_rate: 1)
      configuration = @subject.new(cooling_rate: cooling_rate)
      metal = Annealing::Metal.new(nil, temperature, configuration)
      Annealing::Step.new(metal, configuration, 0)
    end
  end
end
