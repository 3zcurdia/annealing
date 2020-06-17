# frozen_string_literal: true

module Annealing
  # It enables the gem configuration
  class Configuration
    attr_accessor :temperature, :cooling_rate, :total_energy_calculator, :logger

    def initialize
      @temperature  = 10_000.0
      @cooling_rate = 0.0003
      @total_energy_calculator = lambda do |enumerable|
        enumerable.each_cons(2).sum do |value_a, value_b|
          value_a.distance(value_b)
        end
      end
      @logger = Logger.new(STDOUT)
    end
  end
end
