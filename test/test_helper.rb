# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "annealing"
require "debug"
require "minitest/autorun"

module Minitest
  class Test
    def teardown
      # Force configuration to be reinitialized
      Annealing.configuration = nil
    end
  end
end
