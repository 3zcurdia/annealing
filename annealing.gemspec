# frozen_string_literal: true

require_relative "lib/annealing/version"

Gem::Specification.new do |spec|
  spec.name          = "annealing"
  spec.version       = Annealing::VERSION
  spec.authors       = ["Luis Ezcurdia", "Chris Bloom"]
  spec.email         = ["ing.ezcurdia@gmail.com", "chrisbloom7@gmail.com"]
  spec.license       = "MIT"

  spec.summary       = "Simulated annealing for Ruby objects"
  spec.description   = "Find near-optimal solutions to complex optimization problems, like the traveling " \
                       "salesperson, by annealing any Ruby object. Define an initial state, an energy measure and " \
                       "a way to change the state; cooling and termination are built in or fully customizable."
  spec.homepage      = "https://ezcurdia.dev/annealing/"
  spec.required_ruby_version = ">= 3.4.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/3zcurdia/annealing"
  spec.metadata["bug_tracker_uri"] = "https://github.com/3zcurdia/annealing/issues"
  spec.metadata["changelog_uri"] = "https://github.com/3zcurdia/annealing/blob/main/CHANGELOG.md"

  spec.files = Dir["lib/**/*.rb"] + %w[LICENSE README.md CHANGELOG.md]
  spec.require_paths = ["lib"]

  spec.metadata["rubygems_mfa_required"] = "true"
end
