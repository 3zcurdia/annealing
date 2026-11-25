# frozen_string_literal: true

require "test_helper"

module Annealing
  class StepTest < Minitest::Test
    def setup
      @state = (1..3).to_a
      @configuration = Annealing::Configuration.new(
        energy_calculator: ->(_) { 42 }
      )
      @metal = Annealing::Metal.new(@state, 100.0, @configuration)
      @step = Annealing::Step.new(@metal, @configuration, 7)
    end

    def test_exposes_the_simulation_snapshot
      assert_equal @state, @step.state
      assert_equal 42, @step.energy
      assert_in_delta 100.0, @step.temperature
    end

    def test_exposes_the_configuration_cooling_rate_and_step_count
      assert_in_delta @configuration.cooling_rate, @step.cooling_rate
      assert_equal 7, @step.steps
    end

    def test_hides_the_metal_and_configuration
      refute_respond_to @step, :metal
      refute_respond_to @step, :configuration
    end
  end
end
