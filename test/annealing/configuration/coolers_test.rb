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
        cooled_temp = cooler.call(nil, @temperature, @cooling_rate, @step)
        assert_in_delta @temperature - @cooling_rate,
                        cooled_temp
      end

      def test_exponential_cooler_reduces_temperature_exponentially
        cooler = @coolers.exponential
        cooled_temp = cooler.call(nil, @temperature, @cooling_rate, @step)
        assert_in_delta @temperature - (Math.exp(@step - 1) * @cooling_rate),
                        cooled_temp
      end

      def test_geometric_cooler_reduces_temperature_geometrically
        ratio = 3
        cooler = @coolers.geometric(ratio)
        cooled_temp = cooler.call(nil, @temperature, @cooling_rate, @step)
        assert_in_delta @temperature - (@cooling_rate * (ratio**(@step - 1))),
                        cooled_temp
      end
    end
  end
end
