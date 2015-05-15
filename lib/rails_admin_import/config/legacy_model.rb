module RailsAdminImport
  module Config
    class LegacyModel
      attr_reader :model_name
      def initialize(model_name)
        @model_name = model_name
      end

      def label(value)
        # Ignored now
        # RailsAdmin object_label_method will be used
      end

      def mapping_key(value)
        config = RailsAdmin.config(model_name)
        config.mapping_key(value)
      end

      def excluded_fields(values)
        config = RailsAdmin.config(model_name)

        # Call appropriate Rails Admin field list methods
        config.include_all_fields
        config.exclude_fields *values
      end

      def extra_fields(values)
        config = RailsAdmin.config(model_name)

        # Call appropriate Rails Admin field list methods
        config.include_all_fields
        values.each do |value|
          config.field value
        end
      end
    end
  end
end
