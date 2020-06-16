# frozen_string_literal: true

module Annealing
  # It manages the total delta of a given collection
  class Pool
    attr_accessor :collection

    def initialize(collection, delta_method: :delta)
      @collection = collection.dup
      @delta_method = delta_method
    end

    def delta
      @delta ||= calc_delta
    end

    def rand_swap!
      idx_a = rand(collection.size)
      idx_b = rand(collection.size)
      collection[idx_b], collection[idx_a] = collection[idx_a], collection[idx_b]
    end

    private

    attr_reader :delta_method

    def calc_delta
      collection.each_cons(2).sum do |a, b|
        a.public_send(delta_method, b)
      end
    end
  end
end
