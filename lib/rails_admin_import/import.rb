require 'open-uri'
  
module RailsAdminImport
  module Import
    extend ActiveSupport::Concern
  
    included do
      self::FILE_FIELDS = self.set_file_fields
  
      self::MANY_TO_MANY_FIELDS = self.set_has_and_belongs_to_many
  
      self::BELONGS_TO_FIELDS = self.set_belongs_to
  
      self::AUTO_EXCLUDED = [:id, :created_at, :updated_at]
      if !self.const_defined?(:EXCLUDED_FIELDS)
        self::EXCLUDED_FIELDS = []
      end
  
      self::IMPORT_FIELDS = self.set_import_fields
    end
  
    module ClassMethods
      def set_file_fields
        fields = []
  
        self.attachment_definitions.each do |k, v|
          fields << k
        end
  
        fields
      end
  
      def set_import_fields
        fields = []  
        self.new.attributes.keys.each do |key|
          fields << key.to_sym
        end
  
        self::BELONGS_TO_FIELDS.each do |key|
          fields.delete("#{key}_id".to_sym)
        end
  
        self::FILE_FIELDS.each do |key|
          fields.delete("#{key}_file_name".to_sym)
          fields.delete("#{key}_content_type".to_sym)
          fields.delete("#{key}_file_size".to_sym)
          fields.delete("#{key}_updated_at".to_sym)
        end
  
        [self::AUTO_EXCLUDED, self::EXCLUDED_FIELDS].flatten.each do |key|
          fields.delete(key)
        end
  
        fields
      end
  
      def set_belongs_to
        attrs = []
        self.reflections.each do |k, v|
          if v.macro == :belongs_to
            attrs << k 
          end
        end
        attrs
      end
  
      def set_has_and_belongs_to_many
        attrs = []
        self.reflections.each do |k, v|
          if v.macro == :has_and_belongs_to_many
            attrs << k.to_s.singularize.to_sym
          end
        end
        attrs
      end 
  
      def run_import(params)
        if !params.has_key?(:file)
          return results = { :success => [], :error => ["You must select a file."] }
        end

        file = CSV.new(params[:file].tempfile)
        map = {}
  
        file.readline.each_with_index do |key, i|
          if self::MANY_TO_MANY_FIELDS.include?(key.to_sym)
            map[key.to_sym] ||= []
            map[key.to_sym] << i
          else
            map[key.to_sym] = i 
          end
        end 
  
        results = { :success => [], :error => [] }
  
        associated_map = {}
        self::BELONGS_TO_FIELDS.flatten.each do |field|
          associated_map[field] = field.to_s.classify.constantize.all.inject({}) { |hash, c| hash[c.send(params[field])] = c.id; hash }
        end
        self::MANY_TO_MANY_FIELDS.flatten.each do |field|
          associated_map[field] = field.to_s.classify.constantize.all.inject({}) { |hash, c| hash[c.send(params[field])] = c; hash }
        end
  
        file.each do |row|
          object = self.import_new(row, map)
          object.import_files(row, map)
          object.import_belongs_to_data(associated_map, row, map)
          object.import_many_to_many_data(associated_map, row, map)
   
          if object.save
            results[:success] << "Created: #{object.import_display}"
          else
            results[:error] << "Failed to create: #{object.import_display}. Errors: #{object.errors.full_messages.join(', ')}."
          end
        end
  
        results
      end
  
      def import_new(row, map)
        new_attrs = {}
        self::IMPORT_FIELDS.each do |key|
          new_attrs[key] = row[map[key]] if map[key]
        end
        self.new(new_attrs)
      end
    end
   
    module InstanceMethods
      def import_files(row, map)
        self.class::FILE_FIELDS.each do |key|
          if map[key] && !row[map[key]].nil?
            format = row[map[key]].match(/[a-z0-9]+$/)
            open("#{Rails.root}/tmp/uploads/#{self.permalink}.#{format}", 'wb') { |file| file << open(row[map[key]]).read }
            self.send("#{key}=", File.open("#{Rails.root}/tmp/uploads/#{self.permalink}.#{format}"))
          end
        end
      end

      def import_belongs_to_data(associated_map, row, map)
        self.class::BELONGS_TO_FIELDS.each do |key|
          if map.has_key?(key) && row[map[key]] != ""
            self.send("#{key}_id=", associated_map[key][row[map[key]]])
          end
        end
      end
  
      def import_many_to_many_data(associated_map, row, map)
        self.class::MANY_TO_MANY_FIELDS.each do |key|
          values = []
  
          map[key] ||= []
          map[key].each do |pos|
            if row[pos] != "" && associated_map[key][row[pos]]
              values << associated_map[key][row[pos]]
            end
          end
  
          if values.any?
            self.send("#{key.to_s.pluralize}=", values)
          end
        end
      end
    end 
  end
end
