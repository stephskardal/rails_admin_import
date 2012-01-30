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
          end
        end

TODO
========

* Testing

Copyright
========

Copyright (c) 2011 End Point & Steph Skardal. See LICENSE.txt for further details.
