# frozen_string_literal: true

module Annealing
  # It manages the total energy of a given collection
  class Metal
    include Configuration::Configurator
    attr_reader :state, :temperature

    def initialize(current_state, current_temperature, **config)
      init_configuration(config)
      @state = current_state
      @temperature = current_temperature

      raise(ArgumentError, "Missing energy calculator function") unless energy_calculator.respond_to?(:call)

      raise(ArgumentError, "Missing state change function") unless state_change.respond_to?(:call)
    end

    def energy
      @energy ||= energy_calculator.call(state)
    end

    # This method is not idempotent!
    # It relies on random probability to select the next state
    def cool!(new_temperature)
      cooled_metal = cool(new_temperature)
      if prefer?(cooled_metal)
        cooled_metal
      else
        @temperature = new_temperature
        self
      end
    end

    def to_s
      format("%<temperature>.4f:%<energy>.4f:%<value>s",
             temperature: temperature,
             energy: energy,
             value: state)
    end

    private

    def energy_calculator
      current_config_for(:energy_calculator)
    end

    def state_change
      current_config_for(:state_change)
    end

    # True if cooled_metal.energy is lower than current energy, otherwise let
    # probability determine if we should accept a higher value over a lower
    # value
    def prefer?(cooled_metal)
      return true if cooled_metal.energy < energy

      energy_delta = energy - cooled_metal.energy
      (Math::E**(energy_delta / cooled_metal.temperature)) > rand
    end

    def cool(new_temperature)
      next_state = state_change.call(state)
      Metal.new(next_state, new_temperature, **configuration_overrides)
    end
  end
end
