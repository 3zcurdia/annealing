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

    # `Metal` calls the bare `rand` (the private `Kernel#rand` instance method), so stubbing the
    # `Kernel.rand` singleton method has no effect on it. Define `rand` on `Metal` for the block.
    def stub_metal_rand(value)
      Annealing::Metal.send(:define_method, :rand) { |*| value }
      yield
    ensure
      Annealing::Metal.send(:remove_method, :rand)
    end
  end
end
