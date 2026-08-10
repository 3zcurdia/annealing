# frozen_string_literal: true

require "test_helper"

module Annealing
  class Configuration
    class CoolersTest < Minitest::Test
      def setup
        @coolers = Annealing::Configuration::Coolers
        @temperature = 500.0
        @cooling_rate = 0.05
        @step = 5
      end

      def test_linear_cooler_reduces_temperature_linearly
        cooler = @coolers.linear
        mock_step = Minitest::Mock.new
        mock_step.expect(:temperature, @temperature)
        mock_step.expect(:cooling_rate, @cooling_rate)
        cooled_temp = cooler.call(mock_step)

        assert_in_delta @temperature - @cooling_rate,
                        cooled_temp
      end

      def test_exponential_cooler_reduces_temperature_exponentially
        cooler = @coolers.exponential
        mock_step = Minitest::Mock.new
        mock_step.expect(:temperature, @temperature)
        mock_step.expect(:cooling_rate, @cooling_rate)
        mock_step.expect(:steps, @step)
        cooled_temp = cooler.call(mock_step)

        assert_in_delta @temperature - (Math.exp(@step - 1) * @cooling_rate),
                        cooled_temp
      end

      def test_geometric_cooler_reduces_temperature_geometrically
        ratio = 3
        cooler = @coolers.geometric(ratio)
        mock_step = Minitest::Mock.new
        mock_step.expect(:temperature, @temperature)
        mock_step.expect(:cooling_rate, @cooling_rate)
        mock_step.expect(:steps, @step)
        cooled_temp = cooler.call(mock_step)

        assert_in_delta @temperature - (@cooling_rate * (ratio**(@step - 1))),
                        cooled_temp
      end
    end
  end
end
