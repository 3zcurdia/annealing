# frozen_string_literal: true

require "test_helper"

module Annealing
  class Configuration
    class TerminatorsTest < Minitest::Test
      def setup
        @terminators = Annealing::Configuration::Terminators
      end

      def test_zero_temperature_terminator_true_when_temperature_is_zero
        terminator = @terminators.temp_is_zero?

        assert terminator.call(step_with(energy: 1, temperature: 0))
        assert terminator.call(step_with(energy: 1, temperature: -1))
        refute terminator.call(step_with(energy: 1, temperature: 1))
      end

      def test_zero_energy_terminator_true_when_energy_is_zero
        terminator = @terminators.energy_or_temp_is_zero?

        assert terminator.call(step_with(energy: 0, temperature: 1))
        assert terminator.call(step_with(energy: 0, temperature: 0))
        assert terminator.call(step_with(energy: -1, temperature: 1))
      end

      def test_energy_or_temp_terminator_true_when_temperature_is_zero
        terminator = @terminators.energy_or_temp_is_zero?

        assert terminator.call(step_with(energy: 1, temperature: 0))
        assert terminator.call(step_with(energy: 1, temperature: -1))
        refute terminator.call(step_with(energy: 1, temperature: 1))
      end

      private

      # Build a real Annealing::Step whose energy and temperature match the
      # given values.
      def step_with(energy:, temperature:)
        configuration = Annealing::Configuration.new(
          energy_calculator: ->(_) { energy }
        )
        metal = Annealing::Metal.new(nil, temperature, configuration)
        Annealing::Step.new(metal, configuration, 0)
      end
    end
  end
end
