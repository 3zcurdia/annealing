# frozen_string_literal: true

module Annealing
  # It runs simulated annealing
  class Simulator
    attr_reader :configuration

    def initialize(config_hash = {})
      @configuration = Annealing.configuration.merge(config_hash)
    end

    def run(initial_state, config_hash = {})
      with_runtime_config(config_hash) do |runtime_config|
        initial_temperature = runtime_config.temperature
        current = Metal.new(initial_state, initial_temperature, runtime_config)
        best = current
        steps = 0
        until termination_condition_met?(current, steps, runtime_config)
          steps += 1
          current = reduce_temperature(current, steps, runtime_config)
          # If the current state has lower energy than the previous best (lowest energy) state
          # we've seen so far, the current state is the new best state.
          best = current if best.energy_greater_than?(current)
        end
        final_or_best(current, best, runtime_config)
      end
    end

    private

    # Wrapper for public methods that may use a custom configuration
    def with_runtime_config(config_hash)
      runtime_config = if config_hash.nil?
                         configuration
                       else
                         configuration.merge(config_hash)
                       end

      runtime_config.validate!
      yield(runtime_config)
    end

    def reduce_temperature(metal, steps, config)
      new_temperature = config.cool_down.call(Step.new(metal, config, steps))
      metal.cool!(new_temperature)
    end

    def termination_condition_met?(metal, steps, config)
      config.termination_condition.call(Step.new(metal, config, steps))
    end

    def final_or_best(final, best, config)
      if config.return_best
        # preserve the final temperature and best energy
        Metal.new(best.state, final.temperature, config,
                  energy: best.energy, iteration: final.iteration)
      else
        final
      end
    end
  end
end
