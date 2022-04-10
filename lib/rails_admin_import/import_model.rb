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

    def display_name
      abstract_model.config.label
    end

    def label_for_model(object)
      object.public_send(label_method)
    end

    def label_method
      @label_method ||= abstract_model.config.object_label_method
    end

    def importable_fields(model_config = config)
      @importable_fields ||= {}
      @importable_fields[model_config] ||= model_config.visible_fields.reject do |f|
        # Exclude id, created_at and updated_at
        model_config.default_excluded_fields.include? f.name
      end
    end

    def model_fields(model_config = config)
      @model_fields ||= {}
      @model_fields[model_config] ||= importable_fields(model_config).select { |f|
        !f.association? || f.association.polymorphic?
      }
    end

    def association_fields
      @association_fields ||= importable_fields.select { |f|
        f.association? && !f.association.polymorphic?
      }
    end

    def single_association_fields
      @single_association_fields ||= association_fields.select { |f|
        !f.multiple?
      }
    end

    def belongs_to_fields
      @belongs_to_fields ||= single_association_fields.select { |f|
        f.type == :belongs_to_association
      }
    end

    def many_association_fields
      @many_association_fields ||= association_fields.select { |f|
        f.multiple?
      }
    end

    def update_lookup_field_names
      if @config.mapping_key_list.present?
        @update_lookup_field_names = @config.mapping_key_list
      else
        @update_lookup_field_names ||= model_fields.map(&:name) + belongs_to_fields.map(&:associated_primary_key)
      end
    end

    def associated_object(field, mapping_field, value)
      klass = association_class(field)
      klass.where(mapping_field => value).first or
        raise AssociationNotFound, "#{klass}.#{mapping_field} = #{value}"
    end

    def association_class(field)
      field.association.klass
    end

    def associated_config(field)
      field.associated_model_config.import
    end

    def associated_model_fields(field)
      @associated_fields ||= {}
      if associated_config(field).mapping_key_list.present?
        @associated_fields[field] ||= associated_config(field).mapping_key_list
      else
        @associated_fields[field] ||= associated_config(field).visible_fields.select { |f|
          !f.association?
        }.map(&:name)
      end
    end

    def has_multiple_values?(field_name)
      plural_name = pluralize_field(field_name)
      many_association_fields.any? { |field| field.name == field_name || field.name == plural_name }
    end

    def pluralize_field(field_name)
      @plural_fields ||= many_association_fields.map(&:name).each_with_object({}) { |name, h|
        h[name.to_s.singularize.to_sym] = name
      }
      @plural_fields[field_name] || field_name
    end
  end
end


