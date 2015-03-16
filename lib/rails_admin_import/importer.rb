require 'open-uri'
require "rails_admin_import/import_logger"

module RailsAdminImport
  class Importer
    def initialize(abstract_model, model_config)
      @abstract_model = abstract_model
      @model_config = model_config
      @model = abstract_model.model
    end

    attr_reader :abstract_model, :model, :model_config

    def file_fields
      unless @file_fields
        attrs = []
        if model.methods.include?(:attachment_definitions) && !model.attachment_definitions.nil?
          attrs = model.attachment_definitions.keys
        end
        @file_fields = attrs - model_config.excluded_fields 
      end
      @file_fields
    end

    def import_fields
      unless @import_fields
        if model_config.included_fields.any?
          fields = model_config.included_fields.map(&:to_s)
        else
          fields = model.new.attributes.keys.dup
        end

        belongs_to_fields.each do |key|
          fields.delete(model.reflections[key].foreign_key)
        end

        file_fields.each do |key|
          fields.delete("#{key}_file_name")
          fields.delete("#{key}_content_type")
          fields.delete("#{key}_file_size")
          fields.delete("#{key}_updated_at")
        end

        [:id, :created_at, :updated_at, *model_config.excluded_fields].each do |key|
          fields.delete(key.to_s)
        end

        @import_fields = fields
      end

      @import_fields
    end

    def belongs_to_fields
      attrs = model.reflections.select { |field, reflection|
        reflection.macro == :belongs_to && !reflection.options.has_key?(:polymorphic)
      }.keys
      attrs - model_config.excluded_fields 
    end

    def many_fields
      attrs = model.reflections.select { |field, reflection|
        [:has_and_belongs_to_many, :has_many].include? reflection.macro
      }.keys
      attrs - model_config.excluded_fields 
    end

    def association_class(field)
      model.reflections[field].klass
    end

    class CSVRecordImporter
      extend Forwardable

      def initialize(filename)
        @csv = CSV.open(params[:file].tempfile, headers: true)

        # TODO: set up encoding conversion
        # csv_string = csv_string.encode(@encoding_to, @encoding_from, invalid: :replace, undef: :replace, replace: '?')
      end

      def_delegator :@csv, :each, :each_record
    end

    class RecordError < StandardError
    end

    def association_mapping(klass, mapping_field)
      klass.pluck(klass.primary_key, mapping_field).
        each_with_object({}) { |(pk, mapping_value), hash| hash[mapping_value] = pk }
    end

    def run_import(params)
      logger     = ImportLogger.new
      begin
        if !params.has_key?(:file)
          return results = { :success => [], :error => ["You must select a file."] }
        end

        if RailsAdminImport.config.logging
          FileUtils.copy(params[:file].tempfile, "#{Rails.root}/log/import/#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}-import.csv")
        end

        update = params.fetch(:update_if_exists, false) ? params[:update_lookup] : nil

        record_importer = CSVRecordImporter.new(params[:file].tempfile)
        
        # TODO: re-implement file size check
        # if file_check.readlines.size > RailsAdminImport.config.line_item_limit
        #   return results = { :success => [], :error => ["Please limit upload file to #{RailsAdminImport.config.line_item_limit} line items."] }
        # end

        # Map all possible associated records to their primary keys
        # This looks super wasteful
        associated_map = {}
        belongs_to_fields.each do |field|
          associated_map[field] = association_mapping(association_class(field), params[field])
        end
        many_fields.each do |field|
          # TODO: Check if this is useful. The old implementation was
          # mapping AR classes instead of mapping primary keys
          associated_map[field] = association_mapping(association_class(field), params[field])
        end


        record_importer.each_record do |record|
          if update && !record.has_key?(update.to_sym)
            fail RecordError, "Your file must contain a column for the 'Update lookup field' you selected."
          end 

          label_method = model_config.label

          file.each do |row|
            object = self.import_initialize(row, map, update)
            object.import_belongs_to_data(associated_map, row, map)
            object.import_many_data(associated_map, row, map)
            object.before_import_save(row, map)

            object.import_files(row, map)

            verb = object.new_record? ? "Create" : "Update"
            if object.errors.empty?
              if object.save
                logger.info "#{Time.now.to_s}: #{verb}d: #{object.send(label_method)}"
                results[:success] << "#{verb}d: #{object.send(label_method)}"
                object.after_import_save(row, map)
              else
                logger.info "#{Time.now.to_s}: Failed to #{verb}: #{object.send(label_method)}. Errors: #{object.errors.full_messages.join(', ')}."
                results[:error] << "Failed to #{verb}: #{object.send(label_method)}. Errors: #{object.errors.full_messages.join(', ')}."
              end
            else
              logger.info "#{Time.now.to_s}: Errors before save: #{object.send(label_method)}. Errors: #{object.errors.full_messages.join(', ')}."
              results[:error] << "Errors before save: #{object.send(label_method)}. Errors: #{object.errors.full_messages.join(', ')}."
            end
          end

        end

        # file = CSV.new(clean)
        # file.readline.each_with_index do |key, i|
        #   key = key.parameterize.underscore
        #   if many_fields.include?(key)
        #     # TODO: Why the array here?
        #     map[key] ||= []
        #     map[key] << i
        #   else
        #     map[key] = i 
        #   end
        # end

        results = { :success => [], :error => [] }


        results
      rescue Exception => e
        logger.info "#{Time.now.to_s}: Unknown exception in import: #{e.inspect}"
        return results = { :success => [], :error => ["Could not upload. Unexpected error: #{e.to_s}"] }
      end

      # FIXME: what's this cruft?
      def import_initialize(row, map, update)
        new_attrs = {}
        self.import_fields.each do |key|
          new_attrs[key] = row[map[key]] if map[key] && !row[map[key]].blank?
        end

        item = nil
        if update.present?
          item = self.send("find_by_#{update}", row[map[update]])
        end 

        if item.nil?
          item = self.new(new_attrs)
        else
          item.attributes = new_attrs.except(update.to_sym)
          item.save
        end
        item
      end
    end

    def import_display
      self.id
    end

    def import_files(row, map)
      if self.valid?
        self.class.file_fields.each do |key|
          if map[key] && !row[map[key]].nil?
            begin
              row[map[key]] = row[map[key]].gsub(/\s+/, "")

              format = row[map[key]].match(/[a-z0-9]+$/)
              permalink = row[map[key]].split('/').last.gsub!('.'+format.to_s,'')

              open("#{Rails.root}/tmp/#{permalink}.#{format}", 'wb') { |file| file << open(row[map[key]]).read }
              self.send("#{key}=", File.open("#{Rails.root}/tmp/#{permalink}.#{format}"))
            rescue Exception => e
              self.errors.add(:base, "Import error: #{e.inspect}")
            end
          end
        end
      end
    end

    def import_belongs_to_data(associated_map, row, map)
      self.class.belongs_to_fields.each do |key|
        if map.has_key?(key) && row[map[key]] != ""
          self.send("#{key}_id=", associated_map[key][row[map[key]]])
        end
      end
    end

    def import_many_data(associated_map, row, map)
      self.class.many_fields.each do |key|
        values = []

        map[key] ||= []
        map[key].each do |pos|
          if row[pos] != "" && associated_map[key][row[pos]]
            values << associated_map[key][row[pos]]
          end
        end

        if values.any?
          self.send("#{key.to_s.pluralize}").push(values)
        end
      end
    end
  end
end

