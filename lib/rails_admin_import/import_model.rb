module RailsAdminImport
  class AssociationNotFound < StandardError
  end

  class ImportModel
    def initialize(abstract_model)
      @abstract_model = abstract_model
      @config = abstract_model.config.import
      @model = abstract_model.model
    end

    attr_reader :abstract_model, :model, :config

    def importable_fields(model_config = config)
      @importable_fields ||= {}
      @importable_fields[model_config] ||= model_config.visible_fields.reject do |f|
        # Exclude id, created_at and updated_at
        model_config.default_excluded_fields.include? f.name
      end
    end

    def model_fields(model_config = config)
      @model_fields ||= {}
      @model_fields[model_config] ||= importable_fields(model_config).select { |f| !f.association? || f.association.polymorphic? }
    end

    def association_fields
      @association_fields ||= importable_fields.select { |f| f.association? && !f.association.polymorphic? }
    end

    def belongs_to_fields
      @belongs_to_fields ||= association_fields.select { |f| !f.multiple? }
    end

    def many_fields
      @many_fields ||= association_fields.select { |f| f.multiple? }
    end

    def associated_object(field, mapping_field, value)
      klass = association_class(field)
      klass.where(mapping_field => value).first or raise AssociationNotFound, "#{klass}.#{mapping_field} = #{value}"
    end

    def association_class(field)
      field.association.klass
    end

    def associated_config(field)
      field.associated_model_config.import
    end

    def associated_model_fields(field)
      @associated_fields ||= {}
      @associated_fields[field] ||= associated_config(field).visible_fields.select { |f| !f.association? }
    end

    def has_multiple_values?(field_name)
      plural_name = pluralize_field(field_name)
      many_fields.any? { |field| field.name == field_name || field.name == plural_name }
    end

    def pluralize_field(field_name)
      @plural_fields ||= many_fields.map(&:name).each_with_object({}) { |name, h|
        h[name.to_s.singularize.to_sym] = name
      }
      @plural_fields[field_name] || field_name
    end
  end
end


