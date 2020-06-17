# frozen_string_literal: true

require 'test_helper'

class AnnealingTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Annealing::VERSION
  end

  def test_distance
    vec_a = Location.new(1, 0)
    vec_b = Location.new(1, 3)
    assert_equal 3, vec_a.distance(vec_b)
  end
end
