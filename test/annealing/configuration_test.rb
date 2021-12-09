# frozen_string_literal: true

require 'test_helper'

module Annealing
  class ConfigurationTest < Minitest::Test
    def setup
      @configuration = Annealing::Configuration.new
    end

    def test_sets_the_default_temperature
      assert_in_delta 10_000.0, @configuration.temperature
    end

    def test_sets_the_default_cooling_rate
      assert_in_delta 0.0003, @configuration.cooling_rate
    end

    def test_sets_the_default_logger
      logger = @configuration.logger
      assert_instance_of Logger, logger
      assert_equal Logger::INFO, @configuration.logger.level
    end

    def test_does_not_set_a_default_energy_calculator
      assert_nil @configuration.energy_calculator
    end

    def test_does_not_set_a_default_state_change_function
      assert_nil @configuration.state_change
    end

    def test_does_not_set_a_default_termination_condition
      assert_nil @configuration.termination_condition
    end
  end
end
