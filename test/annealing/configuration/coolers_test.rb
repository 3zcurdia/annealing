# frozen_string_literal: true

require "test_helper"

module Annealing
  class Configuration
    class CoolersTest < Minitest::Test
      STEP_LIMIT = 10_000

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

      def test_linear_cooler_reaches_zero
        assert_operator steps_to_reach_zero(@coolers.linear), :<, STEP_LIMIT
      end

      def test_exponential_cooler_reduces_temperature_exponentially
        cooler = @coolers.exponential
        cooled_temp = cooler.call(nil, @temperature, @cooling_rate, @step)

        assert_in_delta @temperature - (Math.exp(@step - 1) * @cooling_rate),
                        cooled_temp
      end

      def test_exponential_cooler_reduces_temperature_by_more_on_each_step
        cooler = @coolers.exponential
        cooled_temp = cooler.call(nil, @temperature, @cooling_rate, 1)
        first = @temperature - cooled_temp
        second = @temperature - cooler.call(nil, @temperature, @cooling_rate, 2)

        assert_in_delta @temperature - @cooling_rate, cooled_temp
        assert_operator second, :>, first
      end

      def test_exponential_cooler_reaches_zero
        assert_operator steps_to_reach_zero(@coolers.exponential), :<, STEP_LIMIT
      end

      def test_geometric_cooler_reduces_temperature_geometrically
        ratio = 3.0
        cooler = @coolers.geometric(ratio)
        cooled_temp = cooler.call(nil, @temperature, @cooling_rate, @step)

        assert_in_delta @temperature - (@cooling_rate * (ratio**(@step - 1))),
                        cooled_temp
      end

      def test_geometric_cooler_defaults_to_a_ratio_of_two
        default = @coolers.geometric.call(nil, @temperature, @cooling_rate, @step)
        explicit = @coolers.geometric(2.0).call(nil, @temperature, @cooling_rate, @step)

        assert_in_delta explicit, default
      end

      def test_geometric_cooler_raises_unless_ratio_is_a_float
        ["2.0", nil].each do |ratio|
          error = assert_raises(ConfigurationError) { @coolers.geometric(ratio) }

          assert_match(/must be a float/i, error.message)
        end
      end

      def test_geometric_cooler_raises_when_ratio_is_below_one
        [0.99, 0.5, 0.0, -2.0].each do |ratio|
          error = assert_raises(ConfigurationError) { @coolers.geometric(ratio) }

          assert_match(/below 1\.0/, error.message)
        end
      end

      def test_geometric_cooler_reaches_zero
        assert_operator steps_to_reach_zero(@coolers.geometric(1.01)), :<, STEP_LIMIT
      end

      private

      # Apply the cooler repeatedly, as the simulator does, and return how many
      # steps it took to reach zero. Stops at STEP_LIMIT so that a cooler that
      # never reaches zero fails the test instead of hanging the suite.
      def steps_to_reach_zero(cooler, temperature: 10.0)
        steps = 0
        while temperature.positive? && steps < STEP_LIMIT
          steps += 1
          temperature = cooler.call(nil, temperature, @cooling_rate, steps)
        end
        steps
      end
    end
  end
end
