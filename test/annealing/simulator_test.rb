# frozen_string_literal: true

require 'test_helper'

describe Annealing::Simulator do
  let(:temperature) { 999 }
  let(:cooling_rate) { 1 }
  let(:simulator) { Annealing::Simulator.new }
  let(:default_energy_calculator) { ->(_) { 42 } }
  let(:default_state_change) { ->(state) { state } }
  let(:collection) { (1..100).to_a.shuffle }

  before do
    Annealing.configure do |config|
      config.temperature = temperature
      config.cooling_rate = cooling_rate
      config.energy_calculator = default_energy_calculator
      config.state_change = default_state_change
    end
  end

  describe '.new' do
    it 'forces temperature to float' do
      refute_kind_of Float, temperature
      simulator = Annealing::Simulator.new(temperature: temperature)
      assert_kind_of Float, simulator.temperature
    end

    it 'forces cooling_rate to float' do
      refute_kind_of Float, cooling_rate
      simulator = Annealing::Simulator.new(cooling_rate: cooling_rate)
      assert_kind_of Float, simulator.cooling_rate
    end

    it 'raises an error if the temperature is negative' do
      assert_raises(ArgumentError, 'Invalid initial temperature') do
        Annealing::Simulator.new(temperature: temperature * -1)
      end
    end
  end

  describe '#run' do
    let(:total_iterations) { temperature / cooling_rate }

    it 'uses the global energy calculator and state change method' do
      global_energy_calculator = MiniTest::Mock.new
      global_state_changer = MiniTest::Mock.new
      (total_iterations + 1).times do
        global_energy_calculator.expect(:call, 42, [collection])
        global_state_changer.expect(:call, collection, [collection])
      end
      global_energy_calculator.expect(:call, 42, [collection])

      Annealing.configure do |config|
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
        config.energy_calculator = global_energy_calculator
        config.state_change = global_state_changer
      end

      simulator.run(collection, energy_calculator: local_energy_calculator,
                                state_change: local_state_changer)
      local_energy_calculator.verify
      local_state_changer.verify
    end

    describe 'with termination condition' do
      it 'uses the global termination condition function if one is set' do
        global_termination_condition = MiniTest::Mock.new
        (total_iterations + 1).times do |i|
          current_temp = temperature - (cooling_rate * i)
          global_termination_condition.expect(:call,
                                              false,
                                              [collection, 42, current_temp])
        end

        Annealing.configure do |config|
          config.termination_condition = global_termination_condition
        end

        simulator.run(collection)
        global_termination_condition.verify
      end

      it 'can override the global termination condition' do
        global_termination_condition = MiniTest::Mock.new
        local_termination_condition = MiniTest::Mock.new
        (total_iterations + 1).times do |i|
          current_temp = temperature - (cooling_rate * i)
          local_termination_condition.expect(:call,
                                             false,
                                             [collection, 42, current_temp])
        end

        Annealing.configure do |config|
          config.termination_condition = global_termination_condition
        end

        simulator.run(collection,
                      termination_condition: local_termination_condition)
        global_termination_condition.verify
        local_termination_condition.verify
      end

      it 'returns early if termination condition is met' do
        global_energy_calculator = MiniTest::Mock.new
        total_iterations = 1 # We'll exit after the temp drops 1 step
        (total_iterations + 1).times do
          global_energy_calculator.expect(:call, 42, [collection])
        end

        global_termination_condition = lambda do |_state, _energy, temp|
          temp == temperature - 1
        end

        Annealing.configure do |config|
          config.energy_calculator = global_energy_calculator
          config.termination_condition = global_termination_condition
        end

        simulator.run(collection)
        global_energy_calculator.verify
      end
    end
  end
end
