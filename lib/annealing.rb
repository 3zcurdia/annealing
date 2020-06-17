# frozen_string_literal: true

require 'logger'
require 'annealing/version'
require 'annealing/pool'
require 'annealing/simulator'

# Simulated Annealing algoritm
# https://en.wikipedia.org/wiki/Simulated_annealing
module Annealing
  class Error < StandardError; end

  def self.simulate(collection, temperature: 10_000.0, cooling_rate: 0.003, total_energy: nil)
    return [] if collection.empty?

    simulator = Simulator.new(temperature: temperature, cooling_rate: cooling_rate)
    simulator.run(collection, total_energy: total_energy).collection
  end
end
