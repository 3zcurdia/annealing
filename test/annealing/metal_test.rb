# frozen_string_literal: true

require 'test_helper'

describe Annealing::Metal do
  let(:default_energy_calculator) do
    ->(collection) { collection.each_with_index.sum { |n, i| Math.exp(i) * n } }
  end
  let(:default_state_change) { ->(collection) { collection.shuffle } }
  let(:collection) { (1..100).to_a.shuffle }
  let(:temperature) { Annealing.configuration.temperature }

  before do
    Annealing.configure do |config|
      config.energy_calculator = default_energy_calculator
      config.state_change = default_state_change
    end
  end

  describe '.new' do
    describe 'when a global energy_calculator has not been defined' do
      before do
        Annealing.configuration.energy_calculator = nil
      end

      it 'raises an error if energy_calculator is not specified' do
        assert_raises(ArgumentError, 'Missing energy calculator function') do
          Annealing::Metal.new(nil)
        end
      end
    end

    describe 'when a global state_change function has not been defined' do
      before do
        Annealing.configuration.state_change = nil
      end

      it 'raises an error if state_change is not specified' do
        assert_raises(ArgumentError, 'Missing state change function') do
          Annealing::Metal.new(nil)
        end
      end
    end
  end

  describe '#energy' do
    it 'calls the energy calculator with the current state' do
      custom_calculator = MiniTest::Mock.new
      custom_calculator.expect(:call, 42, [collection])
      metal = Annealing::Metal.new(collection,
                                   energy_calculator: custom_calculator)
      assert_equal 42, metal.energy
    end
  end

  describe '#cooled' do
    it 'returns a metal instance' do
      metal = Annealing::Metal.new(collection)
      cooled_metal = metal.cooled(temperature)
      assert_instance_of Annealing::Metal, cooled_metal
    end

    it 'calls the state change function with the current state' do
      custom_state_changer = MiniTest::Mock.new
      custom_state_changer.expect(:call, [], [collection])
      metal = Annealing::Metal.new(collection,
                                   state_change: custom_state_changer)
      metal.cooled(temperature)
      custom_state_changer.verify
    end

    describe 'when #better_than? is true' do
      it 'returns the cooled metal' do
        metal = Annealing::Metal.new(collection)
        cooled_metal = metal.stub(:better_than?, true) do
          metal.cooled(temperature)
        end
        refute_same metal, cooled_metal
      end
    end

    describe 'when #better_than? is false' do
      it 'returns the original metal' do
        metal = Annealing::Metal.new(collection)
        cooled_metal = metal.stub(:better_than?, false) do
          metal.cooled(temperature)
        end
        assert_same metal, cooled_metal
      end
    end
  end

  describe 'better_than?' do
    let(:current_energy) { 42 }
    let(:cooled_energy) { current_energy }

    it 'calls the energy calculator on the cooled state' do
      changed_collection = collection.shuffle
      custom_calculator = MiniTest::Mock.new
      custom_calculator.expect(:call, current_energy, [collection])
      custom_calculator.expect(:call, cooled_energy, [changed_collection])

      metal = Annealing::Metal.new(collection,
                                   energy_calculator: custom_calculator)
      cooled_metal = Annealing::Metal.new(changed_collection,
                                          energy_calculator: custom_calculator)
      metal.better_than?(cooled_metal, temperature)
      custom_calculator.verify
    end

    describe 'when the difference between energies is positive' do
      let(:cooled_energy) { current_energy / 2 }

      it 'returns true' do
        metal = Annealing::Metal.new(collection)
        cooled_metal = Annealing::Metal.new(collection.shuffle)
        metal.stub(:energy, current_energy) do
          cooled_metal.stub(:energy, cooled_energy) do
            assert metal.better_than?(cooled_metal, temperature)
          end
        end
      end
    end

    describe 'when the difference between energies is negative' do
      let(:cooled_energy) { current_energy * 2 }

      describe 'when the probability of accepting a worse solution is 0' do
        let(:probability) { 0 }

        it 'returns true' do
          metal = Annealing::Metal.new(collection)
          cooled_metal = Annealing::Metal.new(collection.shuffle)
          metal.stub(:energy, current_energy) do
            cooled_metal.stub(:energy, cooled_energy) do
              metal.stub(:rand, probability) do
                assert metal.better_than?(cooled_metal, temperature)
              end
            end
          end
        end
      end

      describe 'when the probability of accepting a worse solution is 1' do
        let(:probability) { 1 }

        it 'returns false' do
          metal = Annealing::Metal.new(collection)
          cooled_metal = Annealing::Metal.new(collection.shuffle)
          metal.stub(:energy, current_energy) do
            cooled_metal.stub(:energy, cooled_energy) do
              metal.stub(:rand, probability) do
                refute metal.better_than?(cooled_metal, temperature)
              end
            end
          end
        end
      end
    end
  end
end
