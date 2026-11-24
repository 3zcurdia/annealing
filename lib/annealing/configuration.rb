# frozen_string_literal: true

module Annealing
  # It enables the gem configuration
  class Configuration
    DEFAULT_COOLING_RATE = 0.0003
    DEFAULT_INITIAL_TEMPERATURE = 10_000.0
    DEFAULT_RETURN_BEST = false

    class ConfigurationError < Annealing::Error; end

    attr_accessor :cool_down,
                  :cooling_rate,
                  :energy_calculator,
                  :return_best,
                  :state_change,
                  :temperature,
                  :termination_condition

    def initialize(config_hash = {})
      @config_options = config_hash.dup
      @cool_down = @config_options.delete(:cool_down) { Coolers.linear }
      @cooling_rate = @config_options.delete(:cooling_rate) { DEFAULT_COOLING_RATE }.to_f
      @energy_calculator = @config_options.delete(:energy_calculator)
      @return_best = @config_options.delete(:return_best) { DEFAULT_RETURN_BEST }
      @state_change = @config_options.delete(:state_change)
      @temperature  = @config_options.delete(:temperature) { DEFAULT_INITIAL_TEMPERATURE }.to_f
      @termination_condition = @config_options.delete(:termination_condition) { Terminators.temp_is_zero? }
    end

    # Return new configuration that merges new attributes with current
    def merge(config_hash)
      raise(ConfigurationError, "Merge options must be a hash") unless config_hash.is_a?(Hash)

      self.class.new(attributes.merge(@config_options).merge(config_hash))
    end

    def validate!
      message = if !callable?(cool_down)
                  "Missing cool down function"
                elsif cooling_rate.negative?
                  "Cooling rate cannot be negative"
                elsif !callable?(energy_calculator)
                  "Missing energy calculator function"
                elsif ![true, false].include?(return_best)
                  "'Return best' specification must be either true or false"
                elsif !callable?(state_change)
                  "Missing state change function"
                elsif temperature.negative?
                  "Initial temperature cannot be negative"
                elsif !callable?(termination_condition)
                  "Missing termination condition function"
                elsif @config_options.any?
                  "Unrecognized configuration options: #{@config_options.keys.sort.join(", ")}"
                end
      raise(ConfigurationError, message) if message
    end

    private

    def attributes
      {
        cool_down: cool_down,
        cooling_rate: cooling_rate,
        energy_calculator: energy_calculator,
        return_best: return_best,
        state_change: state_change,
        temperature: temperature,
        termination_condition: termination_condition
      }
    end

    def callable?(attribute)
      attribute.respond_to?(:call)
    end
  end
end

require "annealing/configuration/coolers"
require "annealing/configuration/terminators"
