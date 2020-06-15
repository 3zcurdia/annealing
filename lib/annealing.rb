# frozen_string_literal: true

require 'annealing/version'

module Annealing
  class Error < StandardError; end

  def self.simulate(_collection, temperature: 10_000.0, cooling_rate: 0.003)
    []
  end
end
