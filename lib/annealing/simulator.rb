# frozen_string_literal: true

module Annealing
  # It runs simulated annealing
  class Simulator
    attr_reader :cooling_rate, :temperature

    def initialize(temperature: nil, cooling_rate: nil)
      @temperature = (temperature || default_temperature).to_f
      @cooling_rate = (cooling_rate || default_cooling_rate).to_f

      raise(ArgumentError, 'Invalid initial temperature') if @temperature.negative?

      raise(ArgumentError, 'Invalid initial cooling rate') if @cooling_rate.negative?
    end

    def run(initial_state, cool_down: nil, energy_calculator: nil, state_change: nil, termination_condition: nil)
      cool_down ||= default_cool_down
      termination_condition ||= default_termination_condition

      raise(ArgumentError, 'Missing cool down function') unless cool_down.respond_to?(:call)

      raise(ArgumentError, 'Missing termination condition function') unless termination_condition.respond_to?(:call)

      current = Metal.new(initial_state, @temperature,
                          energy_calculator: energy_calculator,
                          state_change: state_change)
      Annealing.logger.debug("Original: #{current}")
      steps = 0
      until termination_condition_met?(termination_condition, current)
        steps += 1
        current = reduce_temperature(cool_down, current, steps)
      end
      Annealing.logger.debug("Optimized: #{current}")
      current
    end

    private

    def reduce_temperature(cool_down, metal, steps)
      new_temperature = cool_down.call(metal.energy, metal.temperature,
                                       cooling_rate, steps)
      metal.cooled(new_temperature)
    end

    def termination_condition_met?(termination_condition, metal)
      termination_condition.call(metal.state, metal.energy, metal.temperature)
    end

    def default_temperature
      Annealing.configuration.temperature
    end

    def default_cooling_rate
      Annealing.configuration.cooling_rate
    end

    def default_cool_down
      Annealing.configuration.cool_down
    end

    def default_termination_condition
      Annealing.configuration.termination_condition
    end
  end
end
