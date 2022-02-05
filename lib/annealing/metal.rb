# frozen_string_literal: true

module Annealing
  # It manages the total energy of a given collection
  class Metal
    attr_reader :state, :temperature

    def initialize(state, temperature, energy_calculator: nil, state_change: nil)
      @state = state
      @temperature = temperature
      @energy_calculator = energy_calculator || default_energy_calculator
      @state_change = state_change || default_state_change

      raise(ArgumentError, 'Missing energy calculator function') unless @energy_calculator.respond_to?(:call)

      raise(ArgumentError, 'Missing state change function') unless @state_change.respond_to?(:call)
    end

    def energy
      @energy ||= @energy_calculator.call(state)
    end

    def cooled(new_temperature)
      cooled_metal = cool(new_temperature)
      if better_than?(cooled_metal)
        cooled_metal
      else
        @temperature = new_temperature
        self
      end
    end

    def better_than?(cooled_metal)
      energy_delta = energy - cooled_metal.energy
      energy_delta.positive? ||
        (Math::E**(energy_delta / cooled_metal.temperature)) > rand
    end

    def to_s
      format('%<temperature>.4f:%<energy>.4f:%<value>s',
             temperature: temperature,
             energy: energy,
             value: state.inspect)
    end

    private

    def cool(new_temperature)
      next_state = @state_change.call(state)
      Metal.new(next_state, new_temperature,
                energy_calculator: @energy_calculator,
                state_change: @state_change)
    end

    def default_energy_calculator
      Annealing.configuration.energy_calculator
    end

    def default_state_change
      Annealing.configuration.state_change
    end
  end
end
