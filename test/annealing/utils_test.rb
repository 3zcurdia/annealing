# frozen_string_literal: true

require 'test_helper'

module Annealing
  class UtilsTest < Minitest::Test
    def test_acceptance_one
      assert_equal 1.0, Utils.acceptance(1, 1, 10_000)
    end

    def test_acceptance_lower_new_delta
      assert_equal 1.0, Utils.acceptance(2, 1, 1)
    end

    def test_acceptance_negative
      assert_equal Math::E, Utils.acceptance(1, 2, -1)
    end
  end
end
