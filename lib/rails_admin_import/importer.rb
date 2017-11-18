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

        if records.count > RailsAdminImport.config.line_item_limit
          return results = {
            success: [],
            error: [I18n.t('admin.import.import_error.line_item_limit', limit: RailsAdminImport.config.line_item_limit)]
          }
        end

        perform_global_callback(:before_import)

        with_transaction do
          records.each do |record|
            catch :skip do
              import_record(record)
            end
          end

          rollback_if_error
        end

        perform_global_callback(:after_import)
      rescue Exception => e
        report_general_error("#{e} (#{e.backtrace.first})")
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
      perform_model_callback(import_model.model, :before_import_find, record)

      if update_lookup && !(update_lookup - record.keys).empty?
        raise UpdateLookupError, I18n.t("admin.import.missing_update_lookup")
      end

      object = find_or_create_object(record, update_lookup)
      return if object.nil?
      action = object.new_record? ? :create : :update

      begin
        perform_model_callback(object, :before_import_associations, record)
        import_single_association_data(object, record)
        import_many_association_data(object, record)
      rescue AssociationNotFound => e
        error = I18n.t("admin.import.association_not_found", :error => e.to_s)
        report_error(object, action, error)
        perform_model_callback(object, :after_import_association_error, record)
        return
      end

      perform_model_callback(object, :before_import_save, record)

      if object.save
        report_success(object, action)
        perform_model_callback(object, :after_import_save, record)
      else
        report_error(object, action, object.errors.full_messages.join(", "))
        perform_model_callback(object, :after_import_error, record)
      end
    end

    def update_lookup
      @update_lookup ||= if params[:update_if_exists] == "1"
                           params[:update_lookup].map(&:to_sym)
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
      logger.info "#{Time.now}: #{message}"
      results[:success] << message
    end

    def report_error(object, action, error)
      object_label = import_model.label_for_model(object)
      message = I18n.t("admin.import.import_error.#{action}",
                       :name => object_label,
                       :error => error)
      logger.info "#{Time.now}: #{message}"
      results[:error] << message
    end

    def report_general_error(error)
      message = I18n.t("admin.import.import_error.general", :error => error)
      logger.info "#{Time.now}: #{message}"
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

    def perform_model_callback(object, method_name, record)
      if object.respond_to?(method_name)
        # Compatibility: Old import hook took 2 arguments.
        # Warn and call with a blank hash as 2nd argument.
        if object.method(method_name).arity == 2
          report_old_import_hook(method_name)
          object.send(method_name, record, {})
        else
          object.send(method_name, record)
        end
      end
    end

    def report_old_import_hook(method_name)
      unless @old_import_hook_reported
        error = I18n.t("admin.import.import_error.old_import_hook",
                       model: import_model.display_name,
                       method: method_name)
        report_general_error(error)
        @old_import_hook_reported = true
      end
    end

    def perform_global_callback(method_name)
      object = import_model.model
      object.send(method_name) if object.respond_to?(method_name)
    end

    def find_or_create_object(record, update)
      field_names = import_model.model_fields.map(&:name)
      new_attrs = record.select do |field_name, value|
        field_names.include?(field_name) && !value.blank?
      end

      model = import_model.model
      object = if update.present?
                 query = update.each_with_object({}) do
                   |field, query| query[field] = record[field]
                 end
                 model.where(query).first
               end

      if object.nil?
        object = model.new
        perform_model_callback(object, :before_import_attributes, record)
        object.attributes = new_attrs
      else
        perform_model_callback(object, :before_import_attributes, record)
        object.attributes = new_attrs.except(update.map(&:to_sym))
      end
      object
    end

    def import_single_association_data(object, record)
      import_model.single_association_fields.each do |field|
        mapping_key = params[:associations][field.name]
        value = extract_mapping(record[field.name], mapping_key)

        if !value.blank?
          object.send "#{field.name}=", import_model.associated_object(field, mapping_key, value)
        end
      end
    end

    def import_many_association_data(object, record)
      import_model.many_association_fields.each do |field|
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
