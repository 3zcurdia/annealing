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

        mock_step_0 = Minitest::Mock.new
        mock_step_0.expect(:temperature, 0)
        assert terminator.call(mock_step_0)

        mock_step_neg = Minitest::Mock.new
        mock_step_neg.expect(:temperature, -1)
        assert terminator.call(mock_step_neg)

        mock_step_pos = Minitest::Mock.new
        mock_step_pos.expect(:temperature, 1)
        refute terminator.call(mock_step_pos)
      end

      def test_zero_energy_terminator_true_when_energy_or_temperature_is_zero
        terminator = @terminators.energy_or_temp_is_zero?

        mock_step = Minitest::Mock.new
        mock_step.expect(:energy, 0)
        mock_step.expect(:temperature, 1)
        assert terminator.call(mock_step)
      end
    end
  end
end
