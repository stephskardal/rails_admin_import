require 'rails_admin_import/config/model'
# require 'active_support/core_ext/class/attribute_accessors'

module RailsAdminImport
  module Config
    class << self
      # Stores model configuration objects in a hash identified by model's class
      # name.
      #
      # @see RailsAdminImport::Config.model
      attr_reader :registry
      attr_accessor :logging
      attr_accessor :line_item_limit

      # Loads a model configuration instance from the registry or registers
      # a new one if one is yet to be added.
      #
      # First argument can be an instance of requested model, its class object,
      # its class name as a string or symbol or a RailsAdminImport::AbstractModel
      # instance.
      #
      # If a block is given it is evaluated in the context of configuration instance.
      #
      # Returns given model's configuration
      #
      # @see RailsAdminImport::Config.registry
      def model(entity_name, &block)
        key     = entity_name.is_a?(String) ? entity_name.to_sym : entity_name.name.to_sym
        config  = @registry[key] ||= RailsAdminImport::Config::Model.new(key.to_s)
        config.instance_eval(&block) if block
        config
      end
            
      # Reset all configurations to defaults.
      #
      # @see RailsAdminImport::Config.registry
      def reset
        @registry         = {}
        @logging          = false
        @line_item_limit  = 1000
      end

      # Reset a provided model's configuration.
      #
      # @see RailsAdminImport::Config.registry
      def reset_model(model)
        key = model.kind_of?(Class) ? model.name.to_sym : model.to_sym
        @registry.delete(key)
      end
    end

    # Set default values for configuration options on load
    self.reset
  end
end
