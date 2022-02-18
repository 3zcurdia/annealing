# frozen_string_literal: true

module Annealing
  # It enables the gem configuration
  class Configuration
    attr_accessor :cool_down,
      :cooling_rate,
      :energy_calculator,
      :logger,
      :state_change,
      :temperature,
      :termination_condition

    def initialize
      @cool_down = lambda do |_energy, temperature, cooling_rate, _steps|
        # Reduce the temperature linearly by default
        temperature - cooling_rate
      end
      @cooling_rate = 0.0003
      @energy_calculator = nil
      @logger = Logger.new($stdout, level: Logger::INFO)
      @state_change = nil
      @temperature  = 10_000.0
      @termination_condition = lambda do |_state, _energy, temperature|
        # Terminate the simulation as soon as the temperature reaches 0
        temperature <= 0.0
      end
    end
  end
end
