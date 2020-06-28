# frozen_string_literal: true

module Annealing
  # It manages the total energy of a given collection
  class Metal
    attr_reader :collection

    def initialize(collection, energy_calculator = nil)
      @collection = collection.dup
      @energy_calculator = energy_calculator || Annealing.configuration.total_energy_calculator
    end

    def energy
      @energy ||= energy_calculator.call(collection)
    end

    def cooled(temperature)
      cooled_metal = self.cool
      energy_delta = energy - cooled_metal.energy
      if energy_delta.positive? || (Math::E**(energy_delta / temperature)) > rand
        cooled_metal
      else
        self
      end
    end

    def to_s
      format('%<energy>.4f:%<value>s', energy: energy, value: collection)
    end

    def cool
      Metal.new(swap_collection, energy_calculator)
    end

    private

    attr_reader :energy_calculator

    def swap_collection
      swapped = collection.dup
      idx_a = rand(size)
      idx_b = rand(size)
      swapped[idx_b], swapped[idx_a] = swapped[idx_a], swapped[idx_b]
      swapped
    end

    def size
      collection.size
    end
  end
end
