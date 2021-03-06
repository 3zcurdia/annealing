# frozen_string_literal: true

module Annealing
  # It runs simulated annealing
  class Simulator
    attr_reader :temperature, :cooling_rate

    def initialize(temperature: nil, cooling_rate: nil)
      @temperature = temperature || Annealing.configuration.temperature
      @cooling_rate = cooling_rate || Annealing.configuration.cooling_rate

      raise 'Invalid initial temperature' if @temperature.negative?

      normalize_cooling_rate
    end

    def run(collection, calculator = nil)
      current = Metal.new(collection.shuffle, calculator)
      Annealing.logger.debug(" Original: #{current}")
      cool_down do |temp|
        current = current.cooled(temp)
      end
      Annealing.logger.debug("Optimized: #{current}")
      current
    end

    private

    def cool_down
      (temperature..0).step(cooling_rate).each { |temp| yield temp }
    end

    def normalize_cooling_rate
      @cooling_rate = -1.0 * cooling_rate if cooling_rate.positive?
    end
  end
end
