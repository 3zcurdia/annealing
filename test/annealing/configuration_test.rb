# frozen_string_literal: true

require 'test_helper'

describe Annealing::Configuration do
  describe '.new' do
    let(:configuration) { Annealing::Configuration.new }

    it 'sets the default temperature' do
      assert_in_delta 10_000.0, configuration.temperature
    end

    it 'sets the default cooling rate' do
      assert_in_delta 0.0003, configuration.cooling_rate
    end

    it 'sets the default logger' do
      logger = configuration.logger
      assert_instance_of Logger, logger
      assert_equal Logger::INFO, configuration.logger.level
    end

    it 'does not set a default energy calculator' do
      assert_nil configuration.energy_calculator
    end

    it 'does not set a default state change function' do
      assert_nil configuration.state_change
    end

    it 'does not set a default termination condition' do
      assert_nil configuration.termination_condition
    end
  end
end
