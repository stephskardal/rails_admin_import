require 'open-uri'
  
module RailsAdminImport
  module Import
    extend ActiveSupport::Concern
  
    module ClassMethods
      def file_fields
        if self.methods.include?(:attachment_definitions) && !self.attachment_definitions.nil?
          return self.attachment_definitions.keys
        end
        [] 
      end
  
      def import_fields
        fields = []  

        fields = self.new.attributes.keys.collect { |key| key.to_sym }
  
        self.belongs_to_fields.each do |key|
          fields.delete("#{key}_id".to_sym)
        end
  
        self.file_fields.each do |key|
          fields.delete("#{key}_file_name".to_sym)
          fields.delete("#{key}_content_type".to_sym)
          fields.delete("#{key}_file_size".to_sym)
          fields.delete("#{key}_updated_at".to_sym)
        end
 
        excluded_fields = RailsAdminImport.config(self).excluded_fields 
        [:id, :created_at, :updated_at, excluded_fields].flatten.each do |key|
          fields.delete(key)
        end
  
        fields
      end
 
      def belongs_to_fields
        self.reflections.select { |k, v| v.macro == :belongs_to }.keys
      end
  
      def many_to_many_fields
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
          if self.many_to_many_fields.include?(key.to_sym)
            map[key.to_sym] ||= []
            map[key.to_sym] << i
          else
            map[key.to_sym] = i 
          end
        end 
  
        results = { :success => [], :error => [] }
  
        associated_map = {}
        self.belongs_to_fields.flatten.each do |field|
          associated_map[field] = field.to_s.classify.constantize.all.inject({}) { |hash, c| hash[c.send(params[field])] = c.id; hash }
        end
        self.many_to_many_fields.flatten.each do |field|
          associated_map[field] = field.to_s.classify.constantize.all.inject({}) { |hash, c| hash[c.send(params[field])] = c; hash }
        end
 
        label_method = RailsAdminImport.config(self).label
 
        file.each do |row|
          object = self.import_new(row, map)
          object.import_files(row, map)
          object.import_belongs_to_data(associated_map, row, map)
          object.import_many_to_many_data(associated_map, row, map)

          object.before_import_save(row, map)
 
          if object.save
            results[:success] << "Created: #{object.send(label_method)}"
          else
            results[:error] << "Failed to create: #{object.send(label_method)}. Errors: #{object.errors.full_messages.join(', ')}."
          end
        end
  
        results
      end
  
      def import_new(row, map)
        new_attrs = {}
        self.import_fields.each do |key|
          new_attrs[key] = row[map[key]] if map[key]
        end
        self.new(new_attrs)
      end
    end
   
    module InstanceMethods
      def before_import_save(*args)
        # Meant to be overridden to do special actions 
      end

      def import_display
        self.id
      end

      def import_files(row, map)
        self.class.file_fields.each do |key|
          if map[key] && !row[map[key]].nil?
            begin
              # Strip file
              row[map[key]] = row[map[key]].gsub(/\s+/, "")
              format = row[map[key]].match(/[a-z0-9]+$/)
              open("#{Rails.root}/tmp/uploads/#{self.permalink}.#{format}", 'wb') { |file| file << open(row[map[key]]).read }
              self.send("#{key}=", File.open("#{Rails.root}/tmp/uploads/#{self.permalink}.#{format}"))
            rescue Exception => e
              self.errors.add(key, "Import error: #{e.inspect}")
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
  
      def import_many_to_many_data(associated_map, row, map)
        self.class.many_to_many_fields.each do |key|
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

class ActiveRecord::Base
  include RailsAdminImport::Import
end
