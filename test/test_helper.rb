# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'annealing'
require 'support/location'
require 'minitest/autorun'
require 'ruby-prof'

class Minitest::Test

  def profile
      RubyProf.start
      yield
      result = RubyProf.stop
      printer = RubyProf::FlatPrinter.new(result)
      printer.print(STDOUT)
  end
end
