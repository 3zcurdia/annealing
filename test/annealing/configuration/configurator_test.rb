# frozen_string_literal: true

require "test_helper"

class TestConfigurator
  include Annealing::Configuration::Configurator

  def cool_down
    current_config_for(:cool_down)
  end

  def cooling_rate
    current_config_for(:cooling_rate).to_f
  end

  def energy_calculator
    current_config_for(:energy_calculator)
  end

  def logger
    current_config_for(:logger)
  end

  def state_change
    current_config_for(:state_change)
  end

  def temperature
    current_config_for(:temperature).to_f
  end

  def termination_condition
    current_config_for(:termination_condition)
  end
end

module Annealing
  class Configuration
    class ConfiguratorTest < Minitest::Test
      def setup
        @global_cool_down = :dummy_global_cool_down
        @global_cooling_rate = 1.0
        @global_energy_calculator = :dummy_global_energy_calculator
        @global_logger = :dummy_global_logger
        @global_temperature = 10.0
        @global_state_change = :dummy_global_state_change

        @instance_config = {
          cool_down: :dummy_instance_cool_down,
          cooling_rate: 10.0,
          energy_calculator: :dummy_instance_energy_calculator,
          logger: :dummy_instance_logger,
          temperature: 100.0,
          state_change: :dummy_instance_state_change
        }

        @local_config = {
          cool_down: :dummy_local_cool_down,
          cooling_rate: 100.0,
          energy_calculator: :dummy_local_energy_calculator,
          logger: :dummy_local_logger,
          temperature: 1_000.0,
          state_change: :dummy_local_state_change
        }

        # Set global defaults
        Annealing.configure do |config|
          config.cool_down = @global_cool_down
          config.cooling_rate = @global_cooling_rate
          config.energy_calculator = @global_energy_calculator
          config.logger = @global_logger
          config.temperature = @global_temperature
          config.state_change = @global_state_change
        end
      end

      def test_adds_config_accessors_that_return_global_config_values_by_default
        instance = TestConfigurator.new
        assert_equal @global_cool_down, instance.cool_down
        assert_equal @global_cooling_rate, instance.cooling_rate
        assert_equal @global_energy_calculator, instance.energy_calculator
        assert_equal @global_logger, instance.logger
        assert_equal @global_temperature, instance.temperature
        assert_equal @global_state_change, instance.state_change
      end

      def test_can_override_global_config_with_instance_config
        instance = TestConfigurator.new(@instance_config)
        assert_equal @instance_config[:cool_down], instance.cool_down
        assert_equal @instance_config[:cooling_rate], instance.cooling_rate
        assert_equal @instance_config[:energy_calculator], instance.energy_calculator
        assert_equal @instance_config[:logger], instance.logger
        assert_equal @instance_config[:temperature], instance.temperature
        assert_equal @instance_config[:state_change], instance.state_change
      end

      def test_can_override_instance_config_with_local_config
        instance = TestConfigurator.new(@instance_config)
        instance.with_configuration_overrides(@local_config) do
          assert_equal @local_config[:cool_down], instance.cool_down
          assert_equal @local_config[:cooling_rate], instance.cooling_rate
          assert_equal @local_config[:energy_calculator], instance.energy_calculator
          assert_equal @local_config[:logger], instance.logger
          assert_equal @local_config[:temperature], instance.temperature
          assert_equal @local_config[:state_change], instance.state_change
        end
      end

      def test_can_override_global_config_with_local_config
        @instance_config = {}
        instance = TestConfigurator.new(@instance_config)
        instance.with_configuration_overrides(@local_config) do
          assert_equal @local_config[:cool_down], instance.cool_down
          assert_equal @local_config[:cooling_rate], instance.cooling_rate
          assert_equal @local_config[:energy_calculator], instance.energy_calculator
          assert_equal @local_config[:logger], instance.logger
          assert_equal @local_config[:temperature], instance.temperature
          assert_equal @local_config[:state_change], instance.state_change
        end
      end

      def test_can_mix_and_match_config_scopes
        instance_config = @instance_config.slice(:energy_calculator, :logger)
        local_config = @local_config.slice(:temperature, :state_change)
        instance = TestConfigurator.new(instance_config)
        instance.with_configuration_overrides(local_config) do
          assert_equal @global_cool_down, instance.cool_down
          assert_equal @global_cooling_rate, instance.cooling_rate
          assert_equal instance_config[:energy_calculator], instance.energy_calculator
          assert_equal instance_config[:logger], instance.logger
          assert_equal local_config[:temperature], instance.temperature
          assert_equal local_config[:state_change], instance.state_change
        end
      end

      def test_instance_configs_do_not_pullute_global_configs
        TestConfigurator.new(@instance_config)
        second_instance = TestConfigurator.new
        assert_equal @global_cool_down, second_instance.cool_down
        assert_equal @global_cooling_rate, second_instance.cooling_rate
        assert_equal @global_energy_calculator, second_instance.energy_calculator
        assert_equal @global_logger, second_instance.logger
        assert_equal @global_temperature, second_instance.temperature
        assert_equal @global_state_change, second_instance.state_change
      end

      def test_local_configs_do_not_pullute_instance_configs
        instance = TestConfigurator.new(@instance_config)

        instance.with_configuration_overrides(@local_config) do
          assert_equal @local_config[:cool_down], instance.cool_down
          assert_equal @local_config[:cooling_rate], instance.cooling_rate
          assert_equal @local_config[:energy_calculator], instance.energy_calculator
          assert_equal @local_config[:logger], instance.logger
          assert_equal @local_config[:temperature], instance.temperature
          assert_equal @local_config[:state_change], instance.state_change
        end

        instance.with_configuration_overrides({}) do
          assert_equal @instance_config[:cool_down], instance.cool_down
          assert_equal @instance_config[:cooling_rate], instance.cooling_rate
          assert_equal @instance_config[:energy_calculator], instance.energy_calculator
          assert_equal @instance_config[:logger], instance.logger
          assert_equal @instance_config[:temperature], instance.temperature
          assert_equal @instance_config[:state_change], instance.state_change
        end
      end

      def test_can_report_on_current_overrides
        instance = TestConfigurator.new
        assert_empty instance.configuration_overrides

        instance_config = @instance_config.slice(:energy_calculator, :logger)
        instance = TestConfigurator.new(instance_config)
        assert_equal({
                       energy_calculator: instance_config[:energy_calculator],
                       logger: instance_config[:logger]
                     }, instance.configuration_overrides)

        local_config = @local_config.slice(:temperature, :state_change)
        instance = TestConfigurator.new(instance_config)
        instance.with_configuration_overrides(local_config) do
          assert_equal({
                         energy_calculator: instance_config[:energy_calculator],
                         logger: instance_config[:logger],
                         temperature: local_config[:temperature],
                         state_change: local_config[:state_change]
                       }, instance.configuration_overrides)
        end
      end
    end
  end
end
