# frozen_string_literal: true

require 'test_helper'

module Annealing
  class MetalTest < Minitest::Test
    def setup
      @collection = (1..100).to_a.shuffle
      @temperature = Annealing.configuration.temperature
      @current_energy = 42

      Annealing.configure do |config|
        config.energy_calculator = lambda do |collection|
          collection.each_with_index.sum { |n, i| Math.exp(i) * n }
        end
        config.state_change = ->(collection) { collection.shuffle }
      end
    end

    def test_new_raises_error_if_energy_calculator_not_specified
      # when a global energy_calculator has not been defined
      Annealing.configuration.energy_calculator = nil
      assert_raises(ArgumentError, 'Missing energy calculator function') do
        Annealing::Metal.new(nil)
      end
    end

    def test_new_raises_error_if_state_change_not_specified
      # when a global state_change function has not been defined
      Annealing.configuration.state_change = nil
      assert_raises(ArgumentError, 'Missing state change function') do
        Annealing::Metal.new(nil)
      end
    end

    def test_energy_calls_energy_calculator_with_current_state
      custom_calculator = MiniTest::Mock.new
      custom_calculator.expect(:call, 42, [@collection])
      metal = Annealing::Metal.new(@collection,
                                   energy_calculator: custom_calculator)
      assert_equal 42, metal.energy
    end

    def test_cooled_returns_metal_instance
      metal = Annealing::Metal.new(@collection)
      cooled_metal = metal.cooled(@temperature)
      assert_instance_of Annealing::Metal, cooled_metal
    end

    def test_cooled_calls_state_change_function_with_current_state
      custom_state_changer = MiniTest::Mock.new
      custom_state_changer.expect(:call, [], [@collection])
      metal = Annealing::Metal.new(@collection,
                                   state_change: custom_state_changer)
      metal.cooled(@temperature)
      custom_state_changer.verify
    end

    def test_cooled_returns_cooled_metal_when_better_than
      metal = Annealing::Metal.new(@collection)
      cooled_metal = metal.stub(:better_than?, true) do
        metal.cooled(@temperature)
      end
      refute_same metal, cooled_metal
    end

    def test_cooled_returns_the_original_metal_when_not_better_than
      metal = Annealing::Metal.new(@collection)
      cooled_metal = metal.stub(:better_than?, false) do
        metal.cooled(@temperature)
      end
      assert_same metal, cooled_metal
    end

    def test_better_than_calls_energy_calculator_on_cooled_state
      cooled_energy = @current_energy
      changed_collection = @collection.shuffle
      custom_calculator = MiniTest::Mock.new
      custom_calculator.expect(:call, @current_energy, [@collection])
      custom_calculator.expect(:call, cooled_energy, [changed_collection])

      metal = Annealing::Metal.new(@collection,
                                   energy_calculator: custom_calculator)
      cooled_metal = Annealing::Metal.new(changed_collection,
                                          energy_calculator: custom_calculator)
      metal.better_than?(cooled_metal, @temperature)
      custom_calculator.verify
    end

    def test_better_than_returns_true_when_positive_difference_between_energies
      cooled_energy = @current_energy / 2
      metal = Annealing::Metal.new(@collection)
      cooled_metal = Annealing::Metal.new(@collection.shuffle)
      metal.stub(:energy, @current_energy) do
        cooled_metal.stub(:energy, cooled_energy) do
          assert metal.better_than?(cooled_metal, @temperature)
        end
      end
    end

    def test_better_than_true_when_negative_energy_delta_zero_probability
      cooled_energy = @current_energy * 2
      probability = 0
      metal = Annealing::Metal.new(@collection)
      cooled_metal = Annealing::Metal.new(@collection.shuffle)
      metal.stub(:energy, @current_energy) do
        cooled_metal.stub(:energy, cooled_energy) do
          metal.stub(:rand, probability) do
            assert metal.better_than?(cooled_metal, @temperature)
          end
        end
      end
    end

    def test_better_than_false_when_negative_energy_delta_nonzero_probability
      cooled_energy = @current_energy * 2
      probability = 1
      metal = Annealing::Metal.new(@collection)
      cooled_metal = Annealing::Metal.new(@collection.shuffle)
      metal.stub(:energy, @current_energy) do
        cooled_metal.stub(:energy, cooled_energy) do
          metal.stub(:rand, probability) do
            refute metal.better_than?(cooled_metal, @temperature)
          end
        end
      end
    end
  end
end
