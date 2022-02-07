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
    global_energy_calculator = MiniTest::Mock.new
    global_state_changer = MiniTest::Mock.new
    total_iterations.times do
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

    Annealing.simulate(collection)
    global_energy_calculator.verify
    global_state_changer.verify
  end

  def test_returns_the_configuration_logger
    logger = Logger.new($stdout)
    Annealing.configure { |config| config.logger = logger }
    assert_same logger, Annealing.logger
  end
end
