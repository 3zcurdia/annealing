# frozen_string_literal: true

module Annealing
  # It runs simulated annealing
  class Simulator
    attr_reader :temperature, :cooling_rate

    def initialize(temperature: nil, cooling_rate: nil)
      @temperature = (temperature || default_temperature).to_f
      @cooling_rate = (cooling_rate || default_cooling_rate).to_f

      raise(ArgumentError, 'Invalid initial temperature') if @temperature.negative?

      raise(ArgumentError, 'Invalid initial cooling rate') if @cooling_rate.negative?
    end

    def run(initial_state, energy_calculator: nil, state_change: nil, termination_condition: nil)
      termination_condition ||= default_termination_condition
      current = Metal.new(initial_state, @temperature,
                          energy_calculator: energy_calculator,
                          state_change: state_change)
      Annealing.logger.debug("Original: #{current}")
      until termination_condition_met?(termination_condition, current) do
        current = cool_down(current)
      end
      Annealing.logger.debug("Optimized: #{current}")
      current
    end

    private

    def cool_down(current)
      current.cooled(current.temperature - cooling_rate)
    end

    def termination_condition_met?(termination_condition, metal)
      # binding.break if metal.temperature <= 1
      if termination_condition.respond_to?(:call)
        termination_condition.call(metal.state, metal.energy, metal.temperature)
      else
        metal.temperature <= 0.0
      end
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
