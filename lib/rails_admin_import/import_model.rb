module RailsAdminImport
  class ImportModel
    def initialize(abstract_model)
      @abstract_model = abstract_model
      @config = abstract_model.config
      @model = abstract_model.model
    end

    attr_reader :abstract_model, :model, :config

    def visible_fields(model_config = config)
      @visible_fields ||= {}
      @visible_fields[config] ||= config.import.visible_fields.reject do |f|
        # Exclude id, created_at and updated_at
        model_config.import.default_excluded_fields.include? f.name
      end
    end

    def model_fields(model_config = config)
      @model_fields ||= visible_fields(model_config).select { |f| !f.association? || f.association.polymorphic? }
    end

    def association_fields
      @association_fields ||= visible_fields.select { |f| f.association? && !f.association.polymorphic? }
    end

    def belongs_to_fields
      @belongs_to_fields ||= association_fields.select { |f| f.type == :belongs_to_association }
    end

    def many_fields
      @many_fields ||= association_fields.select do |f|
        [:has_and_belongs_to_many_association, :has_many_association].include?(f.type)
      end
    end

    def associated_object(field, mapping_field, value)
      association_class(field).find_by(mapping_field => value)
    end

    def associated_config(field)
      field.associated_model_config.import
    end

    def associated_model_fields(field)
      model_fields(field.associated_model_config)
    end

    def has_multiple_values?(field_name)
      association = @abstract_model.associations.find { |a| a.name == field_name }
      !association.nil? && [:has_and_belongs_to_many, :has_many].include?(association.type)
    end
  end
end


