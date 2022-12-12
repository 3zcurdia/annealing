# frozen_string_literal: true

module Annealing
  class Configuration
    # Built-in cool down functions
    module Coolers
      module_function

      # Reduce temperature linearly by the cooling rate
      def linear
        lambda { |_energy, temperature, cooling_rate, _steps|
          temperature - cooling_rate
        }
      end

      # Reduce temperature exponentially on each step by the cooling rate
      def exponential
        lambda { |_energy, temperature, cooling_rate, steps|
          temperature - (Math.exp(steps - 1) * cooling_rate)
        }
      end

      # Reduce temperature geometrically at a given ratio by the cooling rate
      def geometric(ratio = 2)
        unless ratio.positive?
          raise(Annealing::Configuration::ConfigurationError,
                "geometric ratio must be positive")
        end

        lambda { |_energy, temperature, cooling_rate, steps|
          temperature - (cooling_rate * (ratio**(steps - 1)))
        }
      end
    end
  end
end
