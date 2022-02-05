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
      @cool_down = nil
      @cooling_rate = 0.0003
      @energy_calculator = nil
      @logger = Logger.new($stdout, level: Logger::INFO)
      @state_change = nil
      @temperature  = 10_000.0
      @termination_condition = nil
    end
  end
end
