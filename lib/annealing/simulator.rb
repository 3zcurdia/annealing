# frozen_string_literal: true

module Annealing
  # It runs simulated annealing
  class Simulator
    attr_reader :temperature, :cooling_rate

    def initialize(temperature:, cooling_rate: -1.0)
      @temperature = temperature
      @cooling_rate = cooling_rate

      raise 'Invalid initial temperature' if temperature.negative?

      normalize_cooling_rate
    end

    def run(collection)
      return Pool.zero if collection.empty?

      best = current = Pool.new(collection.shuffle)
      logger.debug(" Original: #{current}")
      cool_down do |temp|
        current = current.solution_at(temp)
        best = current if current.better_than?(best)
      end
      logger.debug("Optimized: #{best}")
      best
    end

    private

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def cool_down
      (temperature..0).step(cooling_rate).each { |temp| yield temp }
    end

    def normalize_cooling_rate
      @cooling_rate = -1.0 * cooling_rate if cooling_rate.positive?
    end
  end
end
