module RailsAdminImport
  module Config
    class << self
      attr_accessor :logging
      attr_accessor :line_item_limit

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
