# frozen_string_literal: true

require "test_helper"

class AnnealingTest < Minitest::Test
  def test_has_a_version_number
    refute_nil ::Annealing::VERSION
  end

  def test_returns_an_instance_of_annealing_configuration
    assert_instance_of Annealing::Configuration, Annealing.configuration
  end

  def test_returns_the_annealed_state_using_the_default_config
    custom_temperature = 1000
    custom_cooling_rate = 1
    total_iterations = custom_temperature / custom_cooling_rate
    collection = (1..10).to_a.shuffle
    global_energy_calculator = Minitest::Mock.new
    global_state_changer = Minitest::Mock.new
    total_iterations.times do
      global_energy_calculator.expect(:call, 42) { |step| step.state == collection }
      global_state_changer.expect(:call, collection) { |step| step.state == collection }
    end
    global_energy_calculator.expect(:call, 42) { |step| step.state == collection }

    Annealing.configure do |config|
      config.temperature = custom_temperature
      config.cooling_rate = custom_cooling_rate
      config.energy_calculator = global_energy_calculator
      config.state_change = global_state_changer
    end

    Annealing.simulate(collection)
    global_energy_calculator.verify
    global_state_changer.verify
  end

  def test_simulate_returns_the_annealed_state
    collection = (1..10).to_a
    Annealing.configure do |config|
      config.temperature = 10
      config.cooling_rate = 1
      config.energy_calculator = ->(step) { step.state.sum }
      config.state_change = lambda(&:state)
    end

    state = Annealing.simulate(collection)

    assert_equal collection, state
    refute_instance_of Annealing::Metal, state
  end

  def test_simulate_returns_the_best_state_by_default
    energies = { a: 5, b: 1, c: 6 }
    state_sequence = %i[b c].each
    call_count = 0
    Annealing.configure do |config|
      config.energy_calculator = ->(step) { energies.fetch(step.state) }
      config.state_change = ->(_step) { state_sequence.next }
      config.cool_down = ->(step) { step.temperature - 1 }
      config.termination_condition = ->(_step) { (call_count += 1) >= 3 }
    end

    Kernel.stub(:rand, 0.0) do
      assert_equal :b, Annealing.simulate(:a)
    end
  end

  def test_configure_returns_the_configuration
    config = Annealing.configure { |configuration| configuration.temperature = 42 }

    assert_instance_of Annealing::Configuration, config
    assert_in_delta 42.0, config.temperature
  end

  def test_setting_the_configuration_to_nil_resets_it_to_the_defaults
    Annealing.configure { |config| config.temperature = 42 }
    Annealing.configuration = nil

    assert_in_delta Annealing::Configuration::DEFAULT_INITIAL_TEMPERATURE,
                    Annealing.configuration.temperature
  end

  def test_configuration_errors_are_annealing_errors
    error = assert_raises(Annealing::Error) do
      Annealing::Configuration.new(
        energy_calculator: ->(_) {},
        state_change: ->(_) {}
      ).tap do |config|
        config.cool_down = nil
        config.validate!
      end
    end

    assert_instance_of Annealing::Configuration::ConfigurationError, error
  end
end
