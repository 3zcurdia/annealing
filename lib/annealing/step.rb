# frozen_string_literal: true

module Annealing
  # Snapshot of the simulation state passed to every custom function. It
  # deliberately hides Metal's non-idempotent methods and the raw
  # Configuration behind a small read-only surface:
  #
  #   state, energy, temperature, cooling_rate, steps
  #
  # Note: calling #energy inside your energy_calculator re-enters the
  # calculator (it is not yet memoized at that point) and will raise
  # SystemStackError. Use #state to compute the energy instead.
  class Step
    attr_reader :steps

    # metal: the Metal being evaluated
    # configuration: the configuration in effect for this simulation
    # steps: the number of steps the annealer has taken so far
    def initialize(metal, configuration, steps)
      @metal = metal
      @configuration = configuration
      @steps = steps
    end

    def state
      metal.state
    end

    def energy
      metal.energy
    end

    def temperature
      metal.temperature
    end

    def cooling_rate
      configuration.cooling_rate
    end

    private

    attr_reader :metal, :configuration
  end
end
