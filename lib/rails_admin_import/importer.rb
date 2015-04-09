require "rails_admin_import/import_logger"

module RailsAdminImport
  class Importer
    def initialize(import_model, params)
      @import_model = import_model
      @params = params
    end

    attr_reader :import_model, :params

    class RecordError < StandardError
    end

    def import(records)
      # binding.pry
      logger     = ImportLogger.new
      begin
        if RailsAdminImport.config.logging
          FileUtils.copy(params[:file].tempfile, "#{Rails.root}/log/import/#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}-import.csv")
        end

        update = params[:update_if_exists] == "1" ? params[:update_lookup].to_sym : nil
        label_method = import_model.abstract_model.config.object_label_method

        # TODO: re-implement file size check
        # if file_check.readlines.size > RailsAdminImport.config.line_item_limit
        #   return results = { :success => [], :error => ["Please limit upload file to #{RailsAdminImport.config.line_item_limit} line items."] }
        # end

        results = { :success => [], :error => [] }

        records.each do |record|
          # binding.pry
          if update && !record.has_key?(update)
            fail RecordError, I18n.t('admin.import.missing_update_lookup')
          end 

          # FIXME: row used to be an array. Now record is a hash
          object = find_or_create_object(record, update)
          import_belongs_to_data(object, record)
          import_has_many_data(object, record)

          perform_model_callback(object, :before_import_save, record)

          object_label = object.send(label_method)

          verb = object.new_record? ? "Create" : "Update"
          if object.valid?
            if object.save
              logger.info "#{Time.now.to_s}: #{verb}d: #{object_label}"
              results[:success] << "#{verb}d: #{object_label}"

              perform_model_callback(object, :after_import_save, record)
            else
              logger.info "#{Time.now.to_s}: Failed to #{verb}: #{object_label}. Errors: #{object.errors.full_messages.join(', ')}."
              results[:error] << "Failed to #{verb}: #{object_label}. Errors: #{object.errors.full_messages.join(', ')}."
            end
          else
            logger.info "#{Time.now.to_s}: Errors before save: #{object_label}. Errors: #{object.errors.full_messages.join(', ')}."
            results[:error] << "Errors before save: #{object_label}. Errors: #{object.errors.full_messages.join(', ')}."
          end
        end

        results
      rescue RecordError => e
        logger.info "#{Time.now.to_s}: Error importing record: #{e.inspect}"
        return { success: [], error: [e.message] }

      rescue Exception => e
        logger.info "#{Time.now.to_s}: Unknown exception in import: #{e.inspect}"
        return { :success => [], :error => ["Could not upload. Unexpected error: #{e.to_s}"] }
      end
    end

    def perform_model_callback(object, method, record)
      # TODO: if arity is 2, split record into headers and data to be
      # compatible with the old version and set a deprecation warning
      if object.respond_to?(method)
        object.send(method, record)
      end
    end

    def find_or_create_object(record, update)
      field_names = import_model.model_fields.map(&:name)
      new_attrs = record.select do |field_name, value|
        field_names.include?(field_name) && !value.blank?
      end

      model = import_model.model
      object = if update.present?
               model.find_by(update => record[update])
             end 

      if object.nil?
        object = model.new(new_attrs)
      else
        object.attributes = new_attrs.except(update.to_sym)
        # FIXME: why is save called here, before the Before save callback??
        # Remove for now
        # object.save
      end
      object
    end

    def import_belongs_to_data(object, record)
      import_model.belongs_to_fields.each do |field|
        mapping_key = params[field.name]
        value = extract_mapping(record[field.name], mapping_key)

        if !value.blank?
          object.send "#{field.name}=", import_model.associated_object(field, mapping_key, value)
        end
      end
    end

    def import_has_many_data(object, record)
      import_model.many_fields.each do |field|
        if record.has_key? field.name
          mapping_key = params[field.name]
          values = record[field.name].reject { |value| value.blank? }.map { |value|
            extract_mapping(value, mapping_key)
          }

          if !values.empty?
            associated = values.map { |value| import_model.associated_object(field, mapping_key, value) }
            object.send "#{field.name}=", associated
          end
        end
      end
    end

    def extract_mapping(value, mapping_key)
      if value.is_a? Hash
        value[mapping_key]
      else
        value
      end
    end
  end
end

