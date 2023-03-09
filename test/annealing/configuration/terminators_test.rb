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

        assert terminator.call(nil, nil, 0)
        assert terminator.call(nil, nil, -1)
        refute terminator.call(nil, nil, 1)
      end

      def test_zero_energy_terminator_true_when_energy_or_temperature_is_zero
        terminator = @terminators.energy_or_temp_is_zero?

        assert terminator.call(nil, 0, 0)
        assert terminator.call(nil, 0, 1)
        assert terminator.call(nil, 1, 0)
        assert terminator.call(nil, 1, -1)
        assert terminator.call(nil, -1, 1)
        refute terminator.call(nil, 1, 1)
      end
    end
  end
end
