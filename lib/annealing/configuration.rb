# frozen_string_literal: true

module Annealing
  # It enables the gem configuration
  class Configuration
    attr_accessor :temperature, :cooling_rate, :logger,
                  :energy_calculator, :state_change

    def initialize
      reset
    end

    def reset
      @temperature  = 10_000.0
      @cooling_rate = 0.0003
      @logger = Logger.new(STDOUT)
      @energy_calculator = nil
      @state_change = nil
    end
  end
end
