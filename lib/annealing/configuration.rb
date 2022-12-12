# frozen_string_literal: true

module Annealing
  # It enables the gem configuration
  class Configuration
    DEFAULT_COOLING_RATE = 0.0003
    DEFAULT_INITIAL_TEMPERATURE = 10_000.0
    DEFAULT_COOL_DOWN = lambda { |_energy, temperature, cooling_rate, _steps|
      # Linear reduction in temperature
      temperature - cooling_rate
    }
    DEFAULT_TERMINATION_CONDITION = lambda { |_state, _energy, temperature|
      # Simulation ends when temperature reaches zero
      temperature <= 0.0
    }

    class ConfigurationError < Annealing::Error; end

    attr_accessor :cool_down,
                  :cooling_rate,
                  :energy_calculator,
                  :state_change,
                  :temperature,
                  :termination_condition

    def initialize(config_hash = {})
      @cool_down = config_hash.fetch(:cool_down, DEFAULT_COOL_DOWN)
      @cooling_rate = config_hash.fetch(:cooling_rate,
                                        DEFAULT_COOLING_RATE).to_f
      @energy_calculator = config_hash.fetch(:energy_calculator, nil)
      @state_change = config_hash.fetch(:state_change, nil)
      @temperature  = config_hash.fetch(:temperature,
                                        DEFAULT_INITIAL_TEMPERATURE).to_f
      @termination_condition = config_hash.fetch(:termination_condition,
                                                 DEFAULT_TERMINATION_CONDITION)
    end

    # Return new configuration that merges new attributes with current
    def merge(config_hash)
      self.class.new(attributes.merge(config_hash))
    end

    def validate!
      message = if !callable?(cool_down)
                  "Missing cool down function"
                elsif cooling_rate.negative?
                  "Cooling rate cannot be negative"
                elsif !callable?(energy_calculator)
                  "Missing energy calculator function"
                elsif !callable?(state_change)
                  "Missing state change function"
                elsif temperature.negative?
                  "Initial temperature cannot be negative"
                elsif !callable?(termination_condition)
                  "Missing termination condition function"
                end
      raise(ConfigurationError, message) if message
    end

    private

    def attributes
      {
        cool_down: cool_down,
        cooling_rate: cooling_rate,
        energy_calculator: energy_calculator,
        state_change: state_change,
        temperature: temperature,
        termination_condition: termination_condition
      }
    end

    def callable?(attribute)
      attribute.respond_to?(:call)
    end
  end
end
