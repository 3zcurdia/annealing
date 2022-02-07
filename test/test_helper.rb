# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "annealing"
require "debug"
require "minitest/autorun"
require "ruby-prof"

module Minitest
  class Test
    def teardown
      Annealing.configuration.reset
    end

    def profile
      RubyProf.start
      yield
      result = RubyProf.stop
      printer = RubyProf::FlatPrinter.new(result)
      printer.print($stdout)
    end
  end
end
