# frozen_string_literal: true

require "test_helper"

module Annealing
  class ConfigurationTest < Minitest::Test
    def setup
      @configuration = Annealing::Configuration.new
    end

    def test_sets_a_default_linear_cool_down_function
      cool_down = @configuration.cool_down
      assert_respond_to cool_down, :call
      assert_equal 1, cool_down.call(nil, 2, 1, nil)
    end

    def test_sets_the_default_cooling_rate
      assert_in_delta 0.0003, @configuration.cooling_rate
    end

    def test_sets_the_default_temperature
      assert_in_delta 10_000.0, @configuration.temperature
    end

    def test_sets_a_default_termination_condition_function
      termination_condition = @configuration.termination_condition
      assert_respond_to termination_condition, :call
      refute termination_condition.call(nil, nil, 1)
      assert termination_condition.call(nil, nil, 0)
      assert termination_condition.call(nil, nil, -1)
    end

    def test_does_not_set_a_default_energy_calculator_function
      assert_nil @configuration.energy_calculator
    end

    def test_does_not_set_a_default_state_change_function
      assert_nil @configuration.state_change
    end
  end
end
