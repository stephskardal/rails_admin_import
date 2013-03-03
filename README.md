Rails Admin Import functionality
========

Plugin functionality to add generic import to Rails Admin interface. This fork specifically adds the ability to ignore duplicate records by some column. 

Installation
========

* First, add to Gemfile:
    
        gem "rails_admin_import", :git => "git://github.com/joelvh/rails_admin_import.git"

* Next, mount in your application by adding following line to your config/routes.rb:

        mount RailsAdminImport::Engine => '/rails_admin_import', :as => 'rails_admin_import'

* Add to cancan to allow access to import in your app/models/ability.rb:

        can :import, [User, Model1, Model2]

* Define configuration in config/initializers/rails_admin.rb:

        RailsAdminImport.config do |config| 
          config.model User do
          
            # Fields to make available for import (whitelist)
            
            included_fields do
              [:field1, :field2, :field3]
            end
            
            # Fields to skip (blacklist)
            
            excluded_fields do
              [:field1, :field2, :field3]
            end
            
            # Custom methods to get/set the values on? (Not in use?)
            
            extra_fields do
              [:field3, :field4, :field5]
            end
            
            # Name of the method on the model to use in alert messages indicating success/failure of import
            
            label :name
            
            # Specifies the field to use to find existing records (when nil, admin page shows dropdown with options)
            
            update_lookup_field do
              :email
            end
            
            # Define instance methods to be hooked into the import process, if special/additional processing is required on the data
            
            before_import_save do
              # block must return an object that responds to the "call" method
              lambda do |model, row, map|
                # skip confirmation email when importing Devise User model
                model.skip_confirmation!
              end
          end
        end

* "import" action must be added inside config.actions block in main application RailsAdmin configuration: config/initializers/rails_admin.rb.

        config.actions do
          # to include all actions, make sure you specify "all", otherwise only the "import" action will be available
          all
          ...
          import
          ...
        end

  Refer to [RailAdmin documentation on custom actions](https://github.com/sferik/rails_admin/wiki/Actions) that must be present in this block.


* TODO: Right now, import doesn't work for fields ending in s, because inflector fails in models ending in s singularly. Belongs_to and many
  mapping needs to be updated to use klasses instead of symbols

TODO
========

* Testing

Copyright
========

Copyright (c) 2012 End Point & Steph Skardal. See LICENSE.txt for further details.
