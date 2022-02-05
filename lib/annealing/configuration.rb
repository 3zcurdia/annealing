# frozen_string_literal: true

module Annealing
  # It enables the gem configuration
  class Configuration
    attr_accessor :cool_down, :cooling_rate, :energy_calculator,
                  :logger, :state_change, :temperature,
                  :termination_condition

    def initialize
      reset
    end

    def reset
      @cool_down = method(:default_cool_down_function)
      @cooling_rate = 0.0003
      @energy_calculator = nil
      @logger = Logger.new($stdout, level: Logger::INFO)
      @state_change = nil
      @temperature  = 10_000.0
      @termination_condition = method(:default_termination_condition)
    end

    private

    # Reduce the temperature linearly
    def default_cool_down_function(_energy, temperature, cooling_rate, _steps)
      temperature - cooling_rate
    end

    # Terminate the simulation as soon as the temperature reaches 0
    def default_termination_condition(_state, _energy, temperature)
      temperature <= 0.0
    end
  end
end
