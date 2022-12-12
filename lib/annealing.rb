# frozen_string_literal: true

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
    configuration
  end

  def self.simulate(initial_state, config_hash = {})
    Simulator.new.run(initial_state, config_hash).state
  end
end

require "annealing/configuration"
require "annealing/metal"
require "annealing/simulator"
require "annealing/version"
