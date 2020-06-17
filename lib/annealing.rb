# frozen_string_literal: true

require 'logger'
require 'annealing/version'
require 'annealing/configuration'
require 'annealing/pool'
require 'annealing/simulator'

# Simulated Annealing algoritm
# https://en.wikipedia.org/wiki/Simulated_annealing
module Annealing
  # Default error class
  class Error < StandardError; end
  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.simulate(collection)
    return [] if collection.empty?

    simulator = Simulator.new
    simulator.run(collection).collection
  end
end
