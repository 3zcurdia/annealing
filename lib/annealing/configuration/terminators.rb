# frozen_string_literal: true

module Annealing
  class Configuration
    # Built-in termination condition check functions
    module Terminators
      module_function

      # Returns true when the temperature is at or below zero
      def temp_is_zero?
        lambda { |step|
          step.temperature <= 0
        }
      end

      # Returns true if a 0-energy state is detected, or when the temperature
      # is at or below zero
      def energy_or_temp_is_zero?
        lambda { |step|
          step.energy <= 0 || temp_is_zero?.call(step)
        }
      end
    end
  end
end
