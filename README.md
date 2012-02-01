Rails Admin Import functionality
========

Plugin functionality to add generic import to Rails Admin interface

Installation
========

* First, add to Gemfile:
    
        gem "rails_admin_import", :git => "git://github.com/stephskardal/demo.git"

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

* Define instance methods to be hooked into the import process:

        # some model
        def before_import_save(row, map)
          self.set_permalink
          self.import_nested_data(row, map)
        end

TODO
========

* Testing

Copyright
========

Copyright (c) 2011 End Point & Steph Skardal. See LICENSE.txt for further details.
