# frozen_string_literal: true

module Annealing
  # It include general utils for simulator
  module Utils
    def self.acceptance(delta, new_delta, temperature)
      return 1.0 if new_delta < delta

      pow = (delta - new_delta) / temperature
      Math::E**pow
    end
  end
end
