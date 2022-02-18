# frozen_string_literal: true

module Annealing
  class Configuration
    # Configuration mixin
    module Configurator
      def self.included(base)
        base.send :include, InstanceMethods
      end

      # Mixin methods
      module InstanceMethods
        def initialize(config_hash = {})
          @instance_configuration = config_hash
          @temporary_configuration = {}
        end

        def with_configuration_overrides(local_config_hash = {})
          @temporary_configuration = local_config_hash
          yield
        ensure
          @temporary_configuration = {}
        end

        def configuration_overrides
          instance_configuration.merge(temporary_configuration)
        end

        private

        attr_accessor :instance_configuration, :temporary_configuration

        def current_config_for(config)
          temporary_configuration[config] ||
            instance_configuration[config] ||
            Annealing.configuration.public_send(config)
        end
      end
    end
  end
end
