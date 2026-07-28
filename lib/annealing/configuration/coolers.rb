# frozen_string_literal: true

module Annealing
  class Configuration
    # Built-in cool down functions
    module Coolers
      module_function

      # Reduce temperature linearly by the cooling rate
      def linear
        lambda { |step|
          step.temperature - step.cooling_rate
        }
      end

      # Reduce temperature exponentially on each step by the cooling rate
      def exponential
        lambda { |step|
          step.temperature - (Math.exp(step.steps - 1) * step.cooling_rate)
        }
      end

      # Reduce temperature geometrically at a given ratio by the cooling rate
      def geometric(ratio = 2)
        unless ratio.positive?
          raise(Annealing::Configuration::ConfigurationError,
                "geometric ratio must be positive")
        end

        lambda { |step|
          step.temperature - (step.cooling_rate * (ratio**(step.steps - 1)))
        }
      end
    end
  end
end
