# frozen_string_literal: true

module Annealing
  # It runs simulated annealing
  class Simulator
    attr_reader :temperature, :cooling_rate

    def initialize(temperature: nil, cooling_rate: nil)
      @temperature = (temperature || default_temperature).to_f
      @cooling_rate = (cooling_rate || default_cooling_rate).to_f

      raise(ArgumentError, 'Invalid initial temperature') if @temperature.negative?

      normalize_cooling_rate
    end

    def run(initial_state, energy_calculator: nil, state_change: nil, termination_condition: nil)
      termination_condition ||= default_termination_condition

      current = Metal.new(initial_state,
                          energy_calculator: energy_calculator,
                          state_change: state_change)
      Annealing.logger.debug("Original: #{current}")
      cool_down do |temp|
        break if termination_condition_met?(termination_condition, current, temp)

        current = current.cooled(temp)
      end
      Annealing.logger.debug("Optimized: #{current}")
      current
    end

    private

    def cool_down(&block)
      (temperature..0).step(cooling_rate).each(&block)
    end

    def normalize_cooling_rate
      @cooling_rate = -1.0 * cooling_rate if cooling_rate.positive?
    end

    def termination_condition_met?(termination_condition, metal, temperature)
      return false unless termination_condition.respond_to?(:call)

      termination_condition.call(metal.state, metal.energy, temperature)
    end

    def default_temperature
      Annealing.configuration.temperature
    end

    def default_cooling_rate
      Annealing.configuration.cooling_rate
    end

    def default_termination_condition
      Annealing.configuration.termination_condition
    end
  end
end
