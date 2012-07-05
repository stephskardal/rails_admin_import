Rails Admin Import functionality
========

Plugin functionality to add generic import to Rails Admin interface

Installation
========

* First, add to Gemfile:
    
        gem "rails_admin_import", :git => "git://github.com/stephskardal/rails_admin_import.git"

* Next, mount in your application by adding:

        mount RailsAdminImport::Engine => '/rails_admin_import', :as => 'rails_admin_import'" to config/routes

* Add to cancan to allow access to import:

        can :import, [User, Model1, Model2]

* Define configuration:

        RailsAdminImport.config do |config| 
          config.model User do
            excluded_fields do
              [:field1, :field2, :field3]
            end
            label :name
            extra_fields do
              [:field3, :field4, :field5]
            end
          end
        end

* (Optional) Define instance methods to be hooked into the import process, if special/additional processing is required on the data:

        # some model
        def before_import_save(row, map)
          self.set_permalink
          self.import_nested_data(row, map)
        end

* "import" action must be added inside config.actions block in main application RailsAdmin configuration.

  config.actions do
    ...
    import

  end

  Refer to RailAdmin documentation on custom actions that must be present in this block.

TODO
========

* Testing

Copyright
========

Copyright (c) 2011 End Point & Steph Skardal. See LICENSE.txt for further details.
