require 'open-uri'
  
module RailsAdminImport
  module Import
    extend ActiveSupport::Concern
  
    module ClassMethods
      def import_config
        @import_config ||= RailsAdminImport.config(self)
      end
      
      def file_fields
        if self.methods.include?(:attachment_definitions) && !self.attachment_definitions.nil?
          attrs = self.attachment_definitions.keys
        else
          attrs = []
        end
        
        attrs - import_config.excluded_fields
      end
  
      def import_fields
        fields = []
        
        if import_config.included_fields.any?
          fields = import_config.included_fields.dup
        else
          fields = self.new.attributes.keys.collect { |key| key.to_sym }
        end
        
        self.belongs_to_fields.each do |key|
          fields.delete(key)
          fields.delete("#{key}_id".to_sym)
        end
        
        self.file_fields.each do |key|
          fields.delete("#{key}_file_name".to_sym)
          fields.delete("#{key}_content_type".to_sym)
          fields.delete("#{key}_file_size".to_sym)
          fields.delete("#{key}_updated_at".to_sym)
        end
        
        [:id, :created_at, :updated_at, import_config.excluded_fields].flatten.each do |key|
          fields.delete(key)
        end
        
        fields
      end
 
      def belongs_to_fields
        attrs = self.model_associations.select{|k, v| [:belongs_to, :embedded_in].include?(v.macro) }.keys.collect(&:to_sym)
        attrs.select{|attr| import_config.included_fields.include?(attr)}# - import_config.excluded_fields 
      end
  
      def many_fields
        associations  = [:has_and_belongs_to_many, :has_many, :embeds_many]
        attrs         = self.model_associations.select{|k, v| associations.include?(v.macro) }.keys.collect(&:to_sym)
        attrs.select{|attr| import_config.included_fields.include?(attr)}# - import_config.excluded_fields 
      end
      
      def model_associations
        # handle Mongoid or ActiveRecord
        associations = self.respond_to?(:relations) ? self.relations : self.reflections
      end
  
      def run_import(params, role, current_user)
        logger = Rails.logger
        
        # begin
          if !params.has_key?(:file)
            return results = { :success => [], :error => ["You must select a file."] }
          end

          if RailsAdminImport.config.logging
            FileUtils.copy(params[:file].tempfile, "#{Rails.root}/log/import/#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}-import.csv")
            logger = Logger.new("#{Rails.root}/log/import/import.log")
          end

          text        = File.read(params[:file].tempfile)
          clean       = text.force_encoding('BINARY').encode('UTF-8', :undef => :replace, :replace => '').gsub(/\n$/, '')
          file_check  = CSV.new(clean)

          if file_check.readlines.size > RailsAdminImport.config.line_item_limit
            return results = { :success => [], :error => ["Please limit upload file to #{RailsAdminImport.config.line_item_limit} line items."] }
          end
  
          map         = {}
          file        = CSV.new(clean)
          
          file.readline.each_with_index do |key, i|
            if self.many_fields.include?(key.to_sym)
              map[key.to_sym] ||= []
              map[key.to_sym] << i
            else
              map[key.to_sym] = i 
            end
          end
          
          if import_config.update_lookup_field
            lookup_field_name = import_config.update_lookup_field
          elsif !params[:update_lookup].blank?
            lookup_field_name = params[:update_lookup].to_sym
          end
          
          if lookup_field_name && !map.has_key?(lookup_field_name)
            return results = { :success => [], :error => ["Your file must contain a column for the 'Update lookup field' you selected."] }
          end 
    
          results = { :success => [], :error => [] }
          associated_map = {}
          
          self.belongs_to_fields.flatten.each do |field|
            associated_map[field] = field.to_s.classify.constantize.all.inject({}) { |hash, c| hash[c.send(params[field]).to_s] = c.id; hash }
          end
          
          self.many_fields.flatten.each do |field|
            associated_map[field] = field.to_s.classify.constantize.all.inject({}) { |hash, c| hash[c.send(params[field]).to_s] = c; hash }
          end
   
          label_method        = import_config.label
          before_import_save  = import_config.before_import_save
          
          # handle nesting in parent object
          if import_config.create_parent
            parent_object = import_config.create_parent.call(role, current_user)
            nested_field  = import_config.nested_field
          end
          
          file.each do |row|
            new_attrs = {}
            
            self.import_fields.each do |key|
              new_attrs[key] = row[map[key]] if map[key]
            end
            
            lookup_field_value = row[map[lookup_field_name]] unless lookup_field_name.blank?
            
            object = self.import_initialize(new_attrs, lookup_field_name, lookup_field_value)
            object.import_belongs_to_data(associated_map, row, map)
            object.import_many_data(associated_map, row, map)
            
            if before_import_save
              before_import_save_args = [object, row, map, role, current_user]
              before_import_save_args << parent_object if parent_object
              
              callback_result         = before_import_save.call(*before_import_save_args)
              skip_nested_save        = callback_result == false && !parent_object.nil?
            end
            
            object.import_files(row, map)
            
            if parent_object
              parent_object.send(nested_field) << object
            end
            
            verb = object.new_record? ? "Create" : "Update"
            
            if object.errors.empty?
              if skip_nested_save
                logger.info "#{Time.now.to_s}: Skipped nested save: #{object.send(label_method)}" if RailsAdminImport.config.logging
                results[:success] << "Skipped nested save: #{object.send(label_method)}"
              elsif object.save
                logger.info "#{Time.now.to_s}: #{verb}d: #{object.send(label_method)}" if RailsAdminImport.config.logging
                results[:success] << "#{verb}d: #{object.send(label_method)}"
              else
                logger.info "#{Time.now.to_s}: Failed to #{verb.downcase}: #{object.send(label_method)}. Errors: #{object.errors.full_messages.join(', ')}." if RailsAdminImport.config.logging
                results[:error] << "Failed to #{verb.downcase}: #{object.send(label_method)}. Errors: #{object.errors.full_messages.join(', ')}."
              end
            else
              logger.info "#{Time.now.to_s}: Errors before save: #{object.send(label_method)}. Errors: #{object.errors.full_messages.join(', ')}." if RailsAdminImport.config.logging
              results[:error] << "Errors before save: #{object.send(label_method)}. Errors: #{object.errors.full_messages.join(', ')}."
            end
          end
          
          if parent_object
            import_config.before_parent_save.call(parent_object, role, current_user) if import_config.before_parent_save
            
            if parent_object.save
              logger.info "#{Time.now.to_s}: Saved #{parent_object.class.name}" if RailsAdminImport.config.logging
              results[:success].unshift "Saved: #{parent_object}"
            else
              logger.info "#{Time.now.to_s}: Failed to save #{parent_object.class.name}. Errors: #{parent_object.errors.full_messages.join(', ')}." if RailsAdminImport.config.logging
              results[:error].unshift "Failed to save #{parent_object.class.name}. Errors: #{parent_object.errors.full_messages.join(', ')}."
            end
            
            import_config.after_parent_save.call(parent_object, role, current_user) if import_config.after_parent_save
            
          end
    
          results
        # rescue Exception => e
          # logger.info "#{Time.now.to_s}: Unknown exception in import: #{e.inspect}"
          # return results = { :success => [], :error => ["Could not upload. Unexpected error: #{e.to_s}"] }
        # end
      end
  
      def import_initialize(new_attrs, lookup_field, lookup_value)
        mass_assignment_role = RailsAdmin.config.attr_accessible_role.call
        # model#where(lookup_field_name => value).first is more ORM compatible (works with Mongoid)
        if lookup_field.present? && (item = self.send(:where, lookup_field => lookup_value).first)
          item.assign_attributes new_attrs.except(lookup_field.to_sym), :as => mass_assignment_role
          #item.save
        else
          item = self.new(new_attrs, :as => mass_assignment_role)
        end
      end
    end
    
    def import_display
      self.id
    end

    def import_files(row, map)
      if self.new_record? && self.valid?
        self.class.file_fields.each do |key|
          if map[key] && !row[map[key]].nil?
            begin
              # Strip file
              row[map[key]] = row[map[key]].gsub(/\s+/, "")
              format = row[map[key]].match(/[a-z0-9]+$/)
              open("#{Rails.root}/tmp/#{self.permalink}.#{format}", 'wb') { |file| file << open(row[map[key]]).read }
              self.send("#{key}=", File.open("#{Rails.root}/tmp/#{self.permalink}.#{format}"))
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
          self.send("#{key.to_s.pluralize}=", values)
        end
      end
    end
  end
end

if defined? ActiveRecord::Base
  class ActiveRecord::Base
    include RailsAdminImport::Import
  end
end