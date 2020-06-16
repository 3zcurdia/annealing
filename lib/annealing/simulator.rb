# frozen_string_literal: true

module Annealing
  # It runs simulated annealing
  class Simulator
    attr_accessor :temperature, :cooling_rate

    def initialize(**data)
      @temperature = data[:temperature]
      @cooling_rate = data[:cooling_rate].negative? ? data[:cooling_rate] : (-1 * data[:cooling_rate])

      raise 'Invalid initial temperature' if temperature.negative?
    end

    def run(collection)
      return Pool.new([]) if collection.empty?

      current = Pool.new(collection.shuffle)
      best = Pool.new(current.collection)
      puts "Original delta: #{current.delta}"

      cool_down do |temp|
        solution = Pool.new(current.collection)
        solution.rand_swap!

        current = solution if acceptance(current.delta, solution.delta, temp) > rand
        best = current if current.delta < best.delta
      end
      puts "Best delta: #{best.delta}"
      best
    end

    private

    def acceptance(delta, new_delta, temperature)
      return 1.0 if new_delta < delta

      pow = (delta - new_delta) / temperature
      Math::E**pow
    end

    def cool_down
      (temperature..0).step(cooling_rate).each do |temp|
        yield temp
      end
    end
  end
end
