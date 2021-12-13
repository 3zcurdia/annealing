# frozen_string_literal: true

module Annealing
  # It manages the total energy of a given collection
  class Metal
    attr_reader :state

    def initialize(state, energy_calculator: nil, state_change: nil)
      @state = state

      @energy_calculator = energy_calculator ||
        Annealing.configuration.energy_calculator
      raise(
        ArgumentError,
        "Missing energy calculator function"
      ) unless @energy_calculator.respond_to?(:call)

      @state_change = state_change ||
        Annealing.configuration.state_change
      raise(
        ArgumentError,
        "Missing state change function"
      ) unless @state_change.respond_to?(:call)
    end

    def energy
      @energy ||= energy_calculator.call(state)
    end

    def cooled(temperature)
      cooled_metal = self.cool
      if better_than?(cooled_metal, temperature)
        cooled_metal
      else
        self
      end
    end

    def better_than?(cooled_metal, temperature)
      energy_delta = energy - cooled_metal.energy
      energy_delta.positive? || (Math::E**(energy_delta / temperature)) > rand
    end

    def to_s
      format('%<energy>.4f:%<value>s', energy: energy, value: state)
    end

    def cool
      Metal.new(next_state, energy_calculator: energy_calculator,
                            state_change: state_change)
    end

    private

    attr_reader :energy_calculator, :state_change

    def next_state
      state_change.call(state)
    end
  end
end
