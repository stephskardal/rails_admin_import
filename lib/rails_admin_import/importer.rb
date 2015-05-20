require "rails_admin_import/import_logger"

module RailsAdminImport
  class Importer
    def initialize(import_model, params)
      @import_model = import_model
      @params = params
    end

    attr_reader :import_model, :params

    class UpdateLookupError < StandardError
    end

    def import(records)
      begin
        init_results

        # TODO: re-implement file size check
        # if file_check.readlines.size > RailsAdminImport.config.line_item_limit
        #   return results = { :success => [], :error => ["Please limit upload file to #{RailsAdminImport.config.line_item_limit} line items."] }
        # end

        with_transaction do
          records.each do |record|
            import_record(record)
          end

          rollback_if_error
        end
      rescue Exception => e
        report_general_error(e.to_s)
      end

      format_results
    end

    private

    def init_results
      @results = { :success => [], :error => [] }
    end

    def with_transaction(&block)
      if RailsAdminImport.config.rollback_on_error &&
        defined?(ActiveRecord)

        ActiveRecord::Base.transaction &block
      else
        block.call
      end
    end

    def rollback_if_error
      if RailsAdminImport.config.rollback_on_error &&
        defined?(ActiveRecord) &&
        !results[:error].empty?

        results[:success] = []
        raise ActiveRecord::Rollback
      end
    end

    def import_record(record)
      if update_lookup && !record.has_key?(update_lookup)
        raise UpdateLookupError, I18n.t("admin.import.missing_update_lookup")
      end 

      object = find_or_create_object(record, update_lookup)
      action = object.new_record? ? :create : :update

      begin
        import_belongs_to_data(object, record)
        import_has_many_data(object, record)
      rescue AssociationNotFound => e
        error = I18n.t("admin.import.association_not_found", :error => e.to_s)
        report_error(object, action, error)
        return
      end

      perform_model_callback(object, :before_import_save, record)

      if object.save
        report_success(object, action)
        perform_model_callback(object, :after_import_save, record)
      else
        report_error(object, action, object.errors.full_messages.join(", "))
      end
    end

    def update_lookup
      @update_lookup ||= if params[:update_if_exists] == "1"
                           params[:update_lookup].to_sym
                         end
    end

    attr_reader :results

    def logger
      @logger ||= ImportLogger.new
    end

    def report_success(object, action)
      object_label = import_model.label_for_model(object)
      message = I18n.t("admin.import.import_success.#{action}",
                       :name => object_label)
      logger.info "#{Time.now.to_s}: #{message}"
      results[:success] << message
    end

    def report_error(object, action, error)
      object_label = import_model.label_for_model(object)
      message = I18n.t("admin.import.import_error.#{action}",
                       :name => object_label,
                       :error => error)
      logger.info "#{Time.now.to_s}: #{message}"
      results[:error] << message
    end

    def report_general_error(error)
      message = I18n.t("admin.import.import_error.general", :error => error)
      logger.info "#{Time.now.to_s}: #{message}"
      results[:error] << message
    end

    def format_results
      imported = results[:success]
      not_imported = results[:error]
      unless imported.empty?
        results[:success_message] = format_result_message("successful", imported)
      end
      unless not_imported.empty?
        results[:error_message] = format_result_message("error", not_imported)
      end

      results
    end

    def format_result_message(type, array)
      result_count = "#{array.size} #{import_model.display_name.pluralize(array.size)}"
      I18n.t("admin.flash.#{type}",
             name: result_count,
               action: I18n.t("admin.actions.import.done"))
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
      end
      object
    end

    def import_belongs_to_data(object, record)
      import_model.belongs_to_fields.each do |field|
        mapping_key = params[:associations][field.name]
        value = extract_mapping(record[field.name], mapping_key)

        if !value.blank?
          object.send "#{field.name}=", import_model.associated_object(field, mapping_key, value)
        end
      end
    end

    def import_has_many_data(object, record)
      import_model.many_fields.each do |field|
        if record.has_key? field.name
          mapping_key = params[:associations][field.name]
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

