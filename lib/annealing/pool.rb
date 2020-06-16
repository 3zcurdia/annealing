# frozen_string_literal: true

module Annealing
  # It manages the total delta of a given collection
  class Pool
    attr_reader :collection

    def self.zero
      new([])
    end

    def initialize(collection, delta_method: :delta)
      @collection = collection.dup
      @delta_method = delta_method
    end

    def delta
      @delta ||= calc_delta
    end

    def better_than?(pool)
      delta < pool.delta
    end

    def solution_at(temperature)
      solution = Pool.new(swap_collection, delta_method: delta_method)
      if Utils.acceptance(delta, solution.delta, temperature) > rand
        solution
      else
        self
      end
    end

    def to_s
      format('%<delta>.4f:%<value>s', delta: delta, value: collection)
    end

    def size
      collection.size
    end

    private

    attr_reader :delta_method

    def swap_collection
      swapped = collection.dup
      idx_a = rand(size)
      idx_b = rand(size)
      swapped[idx_b], swapped[idx_a] = swapped[idx_a], swapped[idx_b]
      swapped
    end

    def calc_delta
      collection.each_cons(2).sum do |value_a, value_b|
        value_a.public_send(delta_method, value_b)
      end
    end
  end
end
