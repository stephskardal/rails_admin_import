require "rails_admin_import/import_logger"

module RailsAdminImport
  class Importer
    def initialize(abstract_model, model_config)
      @abstract_model = abstract_model
      @model_config = model_config
      @model = abstract_model.model
    end

    attr_reader :abstract_model, :model, :model_config

    def import_fields
      @import_fields ||= begin
        if model_config.included_fields.any?
          fields = model_config.included_fields.map(&:to_s)
        else
          fields = model.new.attributes.keys.dup
        end

        belongs_to_fields.each do |key|
          fields.delete(model.reflections[key].foreign_key)
        end

        [:id, :created_at, :updated_at, *model_config.excluded_fields].each do |key|
          fields.delete(key.to_s)
        end

        fields
      end
    end

    def belongs_to_fields
      @belongs_to_fields ||= begin
        attrs = model.reflections.select { |field, reflection|
          reflection.macro == :belongs_to && !reflection.options.has_key?(:polymorphic)
        }.keys
        attrs - model_config.excluded_fields 
      end
    end

    def many_fields
      @many_fields ||= begin
        attrs = model.reflections.select { |field, reflection|
          [:has_and_belongs_to_many, :has_many].include? reflection.macro
        }.keys
        attrs - model_config.excluded_fields 
      end
    end

    def association_class(field)
      model.reflections[field].klass
    end

    HEADER_CONVERTER = lambda do |header|
      header.parameterize.underscore
    end

    class CSVRecordImporter
      extend Forwardable

      def initialize(filename)
        @csv = CSV.open(filename, headers: true, header_converters: HEADER_CONVERTER)

        # TODO: set up encoding conversion
        # csv_string = csv_string.encode(@encoding_to, @encoding_from, invalid: :replace, undef: :replace, replace: '?')
      end

      attr_reader :csv

      def each_record
        return enum_for(:each_record) unless block_given?
        
        csv.each do |row|
          yield convert_to_hash(row)
        end
      end

      private

      def convert_to_hash(row)
        row.each_with_object({}) do |(header, value), record|
          # When multiple columns with the same name exist, wrap the values in an array
          if record.has_key?(header)
            record[header] = [*record[header], value]
          else
            record[header] = value
          end
        end
      end
    end

    class RecordError < StandardError
    end

    def run_import(params)
      # binding.pry
      logger     = ImportLogger.new
      begin
        if !params.has_key?(:file)
          return results = { :success => [], :error => ["You must select a file."] }
        end

        if RailsAdminImport.config.logging
          FileUtils.copy(params[:file].tempfile, "#{Rails.root}/log/import/#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}-import.csv")
        end

        update = params[:update_if_exists] == "1" ? params[:update_lookup] : nil
        label_method = model_config.label

        record_importer = CSVRecordImporter.new(params[:file].tempfile)
        
        # TODO: re-implement file size check
        # if file_check.readlines.size > RailsAdminImport.config.line_item_limit
        #   return results = { :success => [], :error => ["Please limit upload file to #{RailsAdminImport.config.line_item_limit} line items."] }
        # end

        results = { :success => [], :error => [] }

        record_importer.each_record do |record|
          # binding.pry
          if update && !record.has_key?(update)
            fail RecordError, "Your file must contain a column for the 'Update lookup field' you selected."
          end 

          # FIXME: row used to be an array. Now record is a hash
          object = find_or_create_object(record, update)
          import_belongs_to_data(object, record)
          import_many_data(object, record)

          perform_model_callback(object, :before_import_save, record)

          object_label = object.send(label_method)

          verb = object.new_record? ? "Create" : "Update"
          if object.errors.empty?
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

        # file = CSV.new(clean)
        # file.readline.each_with_index do |key, i|
        #   key = key.parameterize.underscore
        #   if many_fields.include?(key)
        #     # TODO: Why the array here?
        #     # Answer: Because many fields can occur multiple times in the CSV file (multiple columns)
        #     map[key] ||= []
        #     map[key] << i
        #   else
        #     map[key] = i 
        #   end
        # end


        results
      rescue RecordError => e
        logger.info "#{Time.now.to_s}: Error importing record: #{e.inspect}"
        return { success: [], error: e.message }

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
      new_attrs = {}
      import_fields.each do |key|
        value = record[key]
        if !value.blank?
          new_attrs[key] = value
        end
      end

      item = nil
      if update.present?
        item = model.find_by(update => record[update])
      end 

      if item.nil?
        item = model.new(new_attrs)
      else
        item.attributes = new_attrs.except(update.to_sym)
        # FIXME: why is save called here, before the Before save callback??
        # Remove for now
        # item.save
      end
      item
    end

    # TODO: move this to the model config
    def import_display
      self.id
    end

    def associated_object(field, mapping_field, value)
      association_class(field).find_by(mapping_field => value)
    end

    def import_belongs_to_data(object, record)
      belongs_to_fields.each do |field|
        value = record[field]
        if !value.blank?
          object.send "#{field}=", associated_object(field, params[field], value)
        end
      end
    end

    def import_many_data(object, record)
      many_fields.each do |field|
        values = []
        index = record.index(field)
        until index.nil?
          values << associated_object(field, params[field], record.field(index))
          index = record.index(field, index)
        end

        if values.any?
          object.send "#{field}=", values
        end
      end
    end
  end
end

