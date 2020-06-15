# frozen_string_literal: true

require 'test_helper'

class AnnealingTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Annealing::VERSION
  end

  def test_simulation
    assert_equal [], Annealing.simulate([], temperature: 10_000.0, cooling_rate: 0.003)
  end
end
