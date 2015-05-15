require 'rails_admin_import/config/legacy_model'

module RailsAdminImport
  module Config
    class << self
      attr_accessor :logging
      attr_accessor :line_item_limit

      def model(model_name, &block)
        warn "RailsAdminImport::Config#model is deprecated. Add a import section for your model inside the rails_admin config block. See the Readme.md for more details"
        legacy_config = RailsAdminImport::Config::LegacyModel.new(model_name)
        legacy_config.instance_eval(&block) if block
        legacy_config
      end

      # Reset all configurations to defaults.
      def reset
        @logging = false
        @line_item_limit = 1000
      end
    end

    # Set default values for configuration options on load
    self.reset
  end
end
