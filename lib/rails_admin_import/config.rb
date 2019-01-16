require "rails_admin_import/config/legacy_model"

module RailsAdminImport
  module Config
    class << self
      attr_accessor :logging
      attr_accessor :line_item_limit
      attr_accessor :rollback_on_error
      attr_accessor :update_if_exists
      attr_accessor :header_converter
      attr_accessor :csv_options
      attr_accessor :pass_filename

      # Default is to downcase headers and add underscores to convert into attribute names
      HEADER_CONVERTER = lambda do |header|
        # check for nil/blank headers
        next if header.blank?
        header.parameterize.underscore
      end

      def model(model_name, &block)
        unless @deprecation_shown
          warn "RailsAdminImport::Config#model is deprecated. " \
            "Add a import section for your model inside the rails_admin " \
            "config block. See the Readme.md for more details"
          @deprecation_shown = true
        end
        legacy_config = RailsAdminImport::Config::LegacyModel.new(model_name)
        legacy_config.instance_eval(&block) if block
        legacy_config
      end

      # Reset all configurations to defaults.
      def reset
        @logging = false
        @line_item_limit = 1000
        @rollback_on_error = false
        @update_if_exists = false
        @header_converter = HEADER_CONVERTER
        @pass_filename = false
        @csv_options = {}
      end
    end

    # Set default values for configuration options on load
    self.reset
  end
end
