# frozen_string_literal: true

module Annealing
  # It manages the total energy of a given collection
  class Metal
    # `iteration` is the number of steps that have been completed to reach the
    # current state. It advances whether or not a proposed state is accepted.
    attr_reader :configuration, :iteration, :state, :temperature

    def initialize(current_state, current_temperature, configuration = nil, energy: nil, iteration: 0)
      @configuration = configuration || Annealing.configuration.merge({})
      @state = current_state
      @temperature = current_temperature
      @iteration = iteration

      # Used to avoid a potentially costly re-compute when we already know the energy
      @energy = energy
      @energy_computed = !energy.nil?
    end

    def energy
      return @energy if @energy_computed

      # The flag is set after the calculation so that a calculation which
      # re-enters this method (by asking a step for its energy) still raises
      # a SystemStackError instead of silently returning a nil energy.
      @energy = configuration.energy_calculator.call(Step.new(self, configuration, iteration))
      @energy_computed = true
      @energy
    end

    # This method is not idempotent!
    # It relies on random probability to select the next state
    def cool!(new_temperature)
      # Clamp the new temperature so it never goes negative
      new_temperature = [new_temperature, 0.0].max

      cooled_metal = cool(new_temperature)
      if prefer?(cooled_metal)
        cooled_metal
      else
        @temperature = new_temperature
        # The step was taken even though the new state was rejected, so the
        # iteration count still advances. This keeps `iteration` in sync with
        # the number of completed steps for the current state.
        @iteration = iteration + 1
        self
      end
    end

    def energy_greater_than?(cooled_metal)
      cooled_metal.energy < energy
    end

    # DEPRECATED - kept to avoid a breaking change to the public API
    alias lower_energy? energy_greater_than?

    private

    # True if cooled_metal.energy is lower than current energy, otherwise let
    # probability determine if we should accept a higher value over a lower
    # value
    def prefer?(cooled_metal)
      energy_greater_than?(cooled_metal) || prefer_despite_higher_energy?(cooled_metal)
    end

    def prefer_despite_higher_energy?(cooled_metal)
      # At zero temperature the exponential below is undefined (0 divided by 0
      # is NaN), so no move is ever accepted. Only strictly better states are
      # accepted once the metal has cooled all the way down.
      return false if cooled_metal.temperature.zero?

      energy_delta = energy - cooled_metal.energy
      Math.exp(energy_delta / cooled_metal.temperature) > rand
    end

    def cool(new_temperature)
      next_state = configuration.state_change.call(Step.new(self, configuration, iteration))
      Metal.new(next_state, new_temperature, configuration, iteration: iteration + 1)
    end
  end
end
