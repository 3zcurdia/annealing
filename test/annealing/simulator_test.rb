# frozen_string_literal: true

require 'test_helper'

describe Annealing::Simulator do
  let(:simulator) { Annealing::Simulator.new }
  let(:default_energy_calculator) do
    ->(collection) { collection.each_with_index.sum { |n, i| Math.exp(i) * n } }
  end
  let(:default_state_change) { ->(collection) { collection.shuffle } }
  let(:collection) { (1..100).to_a.shuffle }

  before do
    Annealing.configure do |config|
      config.energy_calculator = default_energy_calculator
      config.state_change = default_state_change
    end
  end

  describe '.new' do
    let(:custom_temperature) { 9_999 }
    let(:custom_cooling_rate) { 1 }

    it 'forces temperature to float' do
      refute_kind_of Float, custom_temperature
      simulator = Annealing::Simulator.new(temperature: custom_temperature)
      assert_kind_of Float, simulator.temperature
    end

    it 'forces cooling_rate to float' do
      refute_kind_of Float, custom_cooling_rate
      simulator = Annealing::Simulator.new(cooling_rate: custom_cooling_rate)
      assert_kind_of Float, simulator.cooling_rate
    end

    it 'raises an error if the temperature is negative' do
      assert_raises(ArgumentError, 'Invalid initial temperature') do
        Annealing::Simulator.new(temperature: custom_temperature * -1)
      end
    end
  end

  describe '#run' do
    let(:custom_temperature) { 1000 }
    let(:custom_cooling_rate) { 1 }
    let(:total_iterations) { custom_temperature / custom_cooling_rate }

    it 'uses the global energy calculator and state change method' do
      global_energy_calculator = MiniTest::Mock.new
      global_state_changer = MiniTest::Mock.new
      (total_iterations + 1).times do
        global_energy_calculator.expect(:call, 42, [collection])
        global_state_changer.expect(:call, collection, [collection])
      end
      global_energy_calculator.expect(:call, 42, [collection])

      Annealing.configure do |config|
        config.temperature = custom_temperature
        config.cooling_rate = custom_cooling_rate
        config.energy_calculator = global_energy_calculator
        config.state_change = global_state_changer
      end

      simulator.run(collection)
      global_energy_calculator.verify
      global_state_changer.verify
    end

    it 'can override the global energy calculator and state change method' do
      global_energy_calculator = MiniTest::Mock.new
      global_state_changer = MiniTest::Mock.new

      local_energy_calculator = MiniTest::Mock.new
      local_state_changer = MiniTest::Mock.new
      (total_iterations + 1).times do
        local_energy_calculator.expect(:call, 42, [collection])
        local_state_changer.expect(:call, collection, [collection])
      end
      local_energy_calculator.expect(:call, 42, [collection])

      Annealing.configure do |config|
        config.temperature = custom_temperature
        config.cooling_rate = custom_cooling_rate
        config.energy_calculator = global_energy_calculator
        config.state_change = global_state_changer
      end

      simulator.run(collection, energy_calculator: local_energy_calculator,
                                state_change: local_state_changer)
      local_energy_calculator.verify
      local_state_changer.verify
    end
  end
end
