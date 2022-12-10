# frozen_string_literal: true

module Annealing
  # It manages the total energy of a given collection
  class Metal
    attr_reader :configuration, :state, :temperature

    def initialize(current_state, current_temperature, configuration = nil)
      @configuration = configuration || Annealing.configuration.merge({})
      @state = current_state
      @temperature = current_temperature
    end

    def energy
      @energy ||= configuration.energy_calculator.call(state)
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

    private

    # True if cooled_metal.energy is lower than current energy, otherwise let
    # probability determine if we should accept a higher value over a lower
    # value
    def prefer?(cooled_metal)
      return true if cooled_metal.energy < energy

      energy_delta = energy - cooled_metal.energy
      (Math::E**(energy_delta / cooled_metal.temperature)) > rand
    end

    def cool(new_temperature)
      next_state = configuration.state_change.call(state)
      Metal.new(next_state, new_temperature, configuration)
    end
  end
end
