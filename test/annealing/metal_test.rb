# frozen_string_literal: true

require "test_helper"

module Annealing
  class MetalTest < Minitest::Test
    def setup
      @collection = (1..100).to_a.shuffle
      @temperature = Annealing.configuration.temperature
      @current_energy = 42

      @global_config = Annealing.configure do |config|
        config.energy_calculator = lambda do |step|
          step.state.each_with_index.sum { |n, i| Math.exp(i) * n }
        end
        config.state_change = ->(step) { step.state.shuffle }
      end
    end

    def test_energy_calls_energy_calculator_with_current_state
      seen_step = nil
      custom_calculator = lambda do |step|
        seen_step = step
        42
      end
      local_config = @global_config.merge(energy_calculator: custom_calculator)
      metal = Annealing::Metal.new(@collection, @temperature, local_config)

      assert_equal 42, metal.energy
      assert_equal @collection, seen_step.state
      assert_equal 0, seen_step.steps
    end

    def test_cooled_returns_metal_instance_with_new_temperature
      metal = Annealing::Metal.new(@collection, @temperature)
      new_temperature = @temperature - 1
      cooled_metal = metal.cool!(new_temperature)

      assert_instance_of Annealing::Metal, cooled_metal
      assert_equal new_temperature, cooled_metal.temperature
    end

    def test_cooled_clamps_negative_temperature_to_zero_float
      metal = Annealing::Metal.new(@collection, @temperature)
      cooled_metal = metal.cool!(-0.1)

      assert_instance_of Float, cooled_metal.temperature
      assert_in_delta(0.0, cooled_metal.temperature)
    end

    def test_cooled_never_accepts_a_worse_state_when_new_temperature_is_negative
      config = @global_config.merge(
        energy_calculator: lambda(&:state), # energy == current state
        state_change: ->(_step) { 1_000 } # proposed state change is always worse
      )
      metal = Annealing::Metal.new(0, 1.0, config)
      cooled_metal = metal.cool!(-1.0)

      assert_in_delta(0.0, cooled_metal.state)
    end

    def test_cooled_calls_state_change_function_with_current_state
      seen_step = nil
      custom_state_changer = lambda do |step|
        seen_step = step
        step.state
      end
      local_config = @global_config.merge(state_change: custom_state_changer)
      metal = Annealing::Metal.new(@collection, @temperature, local_config)
      cooled_metal = metal.cool!(@temperature)

      assert_equal @collection, seen_step.state
      assert_equal 0, seen_step.steps
      assert_same @collection, cooled_metal.state
    end

    def test_cool_increments_the_iteration_count
      metal = Annealing::Metal.new(@collection, @temperature)
      cooled_metal = metal.stub(:prefer?, true) { metal.cool!(@temperature) }

      assert_equal 0, metal.iteration
      assert_equal 1, cooled_metal.iteration
    end

    def test_cool_increments_the_iteration_count_when_the_new_state_is_rejected
      metal = Annealing::Metal.new(@collection, @temperature)
      cooled_metal = metal.stub(:prefer?, false) { metal.cool!(@temperature) }

      assert_same metal, cooled_metal
      assert_equal 1, cooled_metal.iteration
    end

    def test_state_change_receives_the_number_of_completed_steps
      seen_steps = []
      config = @global_config.merge(
        state_change: lambda do |step|
          seen_steps << step.steps
          step.state
        end
      )
      metal = Annealing::Metal.new(@collection, @temperature, config)
      metal.stub(:prefer?, false) { metal.cool!(@temperature) }
      metal.stub(:prefer?, false) { metal.cool!(@temperature) }

      assert_equal [0, 1], seen_steps
    end

    def test_energy_can_be_provided_on_initialization
      calls = 0
      config = @global_config.merge(energy_calculator: ->(_step) { calls += 1 })
      metal = Annealing::Metal.new(@collection, @temperature, config, energy: 99)

      assert_equal 99, metal.energy
      assert_equal 0, calls
    end

    def test_iteration_can_be_provided_on_initialization
      metal = Annealing::Metal.new(@collection, @temperature, nil, iteration: 7)

      assert_equal 7, metal.iteration
    end

    def test_energy_is_only_calculated_once_even_when_the_calculator_returns_nil
      calls = 0
      config = @global_config.merge(
        energy_calculator: lambda do |_step|
          calls += 1
          nil
        end
      )
      metal = Annealing::Metal.new(@collection, @temperature, config)

      metal.energy
      metal.energy

      assert_equal 1, calls
    end

    def test_cooled_returns_cooled_metal_when_preferred
      metal = Annealing::Metal.new(@collection, @temperature)
      new_temperature = @temperature - 1
      cooled_metal = metal.stub(:prefer?, true) do
        metal.cool!(new_temperature)
      end

      refute_same metal, cooled_metal
      refute_equal new_temperature, metal.temperature
    end

    def test_cooled_returns_the_original_metal_when_not_preferred
      metal = Annealing::Metal.new(@collection, @temperature)
      new_temperature = @temperature - 1
      cooled_metal = metal.stub(:prefer?, false) do
        metal.cool!(new_temperature)
      end

      assert_same metal, cooled_metal
      assert_equal new_temperature, metal.temperature
    end

    def test_prefer_calls_energy_calculator_on_cooled_state
      cooled_energy = @current_energy
      changed_collection = @collection.shuffle
      seen_states = []
      custom_calculator = lambda do |step|
        seen_states << step.state.object_id
        step.state.equal?(changed_collection) ? cooled_energy : @current_energy
      end
      local_config = @global_config.merge(energy_calculator: custom_calculator)

      metal = Annealing::Metal.new(@collection, @temperature, local_config)
      cooled_metal = Annealing::Metal.new(changed_collection, @temperature,
                                          local_config)
      metal.send(:prefer?, cooled_metal)

      assert_equal [changed_collection.object_id, @collection.object_id],
                   seen_states
    end

    def test_prefer_returns_true_when_cooled_metal_has_lower_energy
      cooled_energy = @current_energy / 2
      metal = Annealing::Metal.new(@collection, @temperature)
      cooled_metal = Annealing::Metal.new(@collection.shuffle, @temperature)
      metal.stub(:energy, @current_energy) do
        cooled_metal.stub(:energy, cooled_energy) do
          assert metal.send(:prefer?, cooled_metal)
        end
      end
    end

    def test_prefer_true_when_compared_energy_higher_and_probability_zero
      cooled_energy = @current_energy * 2
      probability = 0
      metal = Annealing::Metal.new(@collection, @temperature)
      cooled_metal = Annealing::Metal.new(@collection.shuffle, @temperature)
      metal.stub(:energy, @current_energy) do
        cooled_metal.stub(:energy, cooled_energy) do
          metal.stub(:rand, probability) do
            assert metal.send(:prefer?, cooled_metal)
          end
        end
      end
    end

    def test_prefer_false_when_compared_energy_higher_and_probability_nonzero
      cooled_energy = @current_energy * 2
      probability = 1
      metal = Annealing::Metal.new(@collection, @temperature)
      cooled_metal = Annealing::Metal.new(@collection.shuffle, @temperature)
      metal.stub(:energy, @current_energy) do
        cooled_metal.stub(:energy, cooled_energy) do
          metal.stub(:rand, probability) do
            refute metal.send(:prefer?, cooled_metal)
          end
        end
      end
    end

    def test_prefer_true_when_the_energies_are_equal_and_the_temperature_is_above_zero
      config = @global_config.merge(energy_calculator: ->(_step) { @current_energy })
      metal = Annealing::Metal.new(@collection, @temperature, config)
      cooled_metal = Annealing::Metal.new(@collection.shuffle, @temperature, config)

      assert metal.send(:prefer?, cooled_metal)
    end

    def test_prefer_false_when_the_energies_are_equal_and_the_temperature_is_zero
      config = @global_config.merge(energy_calculator: ->(_step) { @current_energy })
      metal = Annealing::Metal.new(@collection, 0.0, config)
      cooled_metal = Annealing::Metal.new(@collection.shuffle, 0.0, config)

      refute metal.send(:prefer?, cooled_metal)
    end

    def test_cooled_does_not_accept_an_equal_state_at_zero_temperature
      config = @global_config.merge(state_change: lambda(&:state))
      metal = Annealing::Metal.new(@collection, 1.0, config)
      cooled_metal = metal.cool!(0.0)

      assert_same metal, cooled_metal
      assert_equal @collection, cooled_metal.state
    end

    def test_lower_energy_is_an_alias_of_energy_greater_than
      metal = Annealing::Metal.new(@collection, @temperature)
      cooled_metal = Annealing::Metal.new(@collection.shuffle, @temperature)
      metal.stub(:energy, @current_energy) do
        cooled_metal.stub(:energy, @current_energy / 2) do
          assert metal.lower_energy?(cooled_metal)
          assert metal.energy_greater_than?(cooled_metal)
        end
      end
    end
  end
end
