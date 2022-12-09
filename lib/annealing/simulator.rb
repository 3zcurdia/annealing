# frozen_string_literal: true

module Annealing
  # It runs simulated annealing
  class Simulator
    include Configuration::Configurator

    def initialize(**config)
      init_configuration(config)
    end

    def run(initial_state, config_hash = {})
      with_configuration_overrides(config_hash) do
        validate_configuration!
        current = Metal.new(initial_state, temperature,
                            **configuration_overrides)
        steps = 0
        until termination_condition_met?(termination_condition, current)
          steps += 1
          current = reduce_temperature(cool_down, current, steps)
        end
        current
      end
    end

    private

    def cool_down
      current_config_for(:cool_down)
    end

    def cooling_rate
      current_config_for(:cooling_rate).to_f
    end

    def temperature
      current_config_for(:temperature).to_f
    end

    def termination_condition
      current_config_for(:termination_condition)
    end

    def reduce_temperature(cool_down, metal, steps)
      new_temperature = cool_down.call(metal.energy, metal.temperature,
                                       cooling_rate, steps)
      metal.cool!(new_temperature)
    end

    def termination_condition_met?(termination_condition, metal)
      termination_condition.call(metal.state, metal.energy, metal.temperature)
    end

    def validate_configuration!
      raise(ArgumentError, "Invalid initial temperature") if temperature.negative?

      raise(ArgumentError, "Invalid initial cooling rate") if cooling_rate.negative?

      raise(ArgumentError, "Missing cool down function") unless cool_down.respond_to?(:call)

      raise(ArgumentError, "Missing termination condition function") unless termination_condition.respond_to?(:call)
    end
  end
end
