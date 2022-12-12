# frozen_string_literal: true

require "test_helper"

module Annealing
  class ConfigurationTest < Minitest::Test
    def setup
      @subject = Annealing::Configuration
      @valid_configuration = @subject.new(
        energy_calculator: ->(*_args) {},
        state_change: ->(*_args) {}
      )
      @error_class = @subject::ConfigurationError
    end

    def test_sets_a_default_linear_cool_down_function
      cool_down = @subject.new.cool_down
      assert_respond_to cool_down, :call
      assert_equal 1, cool_down.call(nil, 2, 1, nil)
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
      refute termination_condition.call(nil, nil, 1)
      assert termination_condition.call(nil, nil, 0)
      assert termination_condition.call(nil, nil, -1)
    end

    def test_does_not_set_a_default_energy_calculator_function
      assert_nil @subject.new.energy_calculator
    end

    def test_does_not_set_a_default_state_change_function
      assert_nil @subject.new.state_change
    end

    def test_forces_cooling_rate_to_float
      configuration = @subject.new(cooling_rate: 99)
      assert_kind_of Float, configuration.cooling_rate
      assert_in_delta 99.0, configuration.cooling_rate
    end

    def test_forces_temperature_to_float
      configuration = @subject.new(temperature: 999)
      assert_kind_of Float, configuration.temperature
      assert_in_delta 999.0, configuration.temperature
    end

    def test_merge_creates_new_configuration_from_config_hash
      new_temperature = 3000
      new_config = @valid_configuration.merge(temperature: new_temperature)
      refute_equal @valid_configuration.object_id, new_config.object_id
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

    def test_validates_temperature_is_not_negative
      @valid_configuration.validate!
      assert_raises(@error_class, "Initial temperature cannot be negative") do
        @valid_configuration.temperature = -100
        @valid_configuration.validate!
      end
    end

    def test_validates_cooling_rate_is_not_negative
      @valid_configuration.validate!
      assert_raises(@error_class, "Cooling rate cannot be negative") do
        @valid_configuration.cooling_rate = -0.005
        @valid_configuration.validate!
      end
    end

    def test_validates_cool_down_funtion_is_callable
      @valid_configuration.validate!
      assert_raises(@error_class, "Missing cool down function") do
        @valid_configuration.cool_down = nil
        @valid_configuration.validate!
      end
    end

    def test_validates_energy_calculator_is_callable
      @valid_configuration.validate!
      assert_raises(@error_class, "Missing energy calculator function") do
        @valid_configuration.termination_condition = nil
        @valid_configuration.validate!
      end
    end

    def test_validates_state_change_is_callable
      @valid_configuration.validate!
      assert_raises(@error_class, "Missing state change function") do
        @valid_configuration.energy_calculator = nil
        @valid_configuration.validate!
      end
    end

    def test_validates_termination_condition_is_callable
      @valid_configuration.validate!
      assert_raises(@error_class, "Missing termination condition function") do
        @valid_configuration.state_change = nil
        @valid_configuration.validate!
      end
    end
  end
end
