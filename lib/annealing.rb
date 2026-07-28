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

# Represents the current state of the annealing process during any given iteration.
Annealing::Step = Struct.new(:metal, :configuration, :iteration) do
  def state; metal.state; end
  def energy; metal.energy; end
  def temperature; metal.temperature; end
  def cooling_rate; configuration.cooling_rate; end
  def steps; iteration; end
end

require "annealing/configuration"
require "annealing/metal"
require "annealing/simulator"
require "annealing/version"
