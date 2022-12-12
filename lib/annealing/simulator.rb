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
        steps = 0
        until termination_condition_met?(current, runtime_config)
          steps += 1
          current = reduce_temperature(current, steps, runtime_config)
        end
        current
      end
    end

    private

    # Wrapper for public methods that may use a custom configuration
    def with_runtime_config(config_hash)
      runtime_config = if config_hash.is_a?(Hash) && config_hash.any?
                         configuration.merge(config_hash)
                       else
                         configuration
                       end
      runtime_config.validate!
      yield(runtime_config)
    end

    def reduce_temperature(metal, steps, config)
      new_temperature = config.cool_down.call(metal.energy,
                                              metal.temperature,
                                              config.cooling_rate,
                                              steps)
      metal.cool!(new_temperature)
    end

    def termination_condition_met?(metal, config)
      config.termination_condition.call(metal.state,
                                        metal.energy,
                                        metal.temperature)
    end
  end
end
