# frozen_string_literal: true

require 'logger'
require 'annealing/version'
require 'annealing/utils'
require 'annealing/pool'
require 'annealing/simulator'

# Simulated Annealing algoritm
# https://en.wikipedia.org/wiki/Simulated_annealing
module Annealing
  class Error < StandardError; end

  def self.simulate(collection, temperature: 10_000.0, cooling_rate: 0.003)
    simulator = Simulator.new(temperature: temperature, cooling_rate: cooling_rate)
    simulator.run(collection).collection
  end
end
