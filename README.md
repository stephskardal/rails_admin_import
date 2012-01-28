Rails Admin Import functionality
========

Plugin functionality to add generic import to Rails Admin interface

Installation
========

* First, add to Gemfile:
    
        gem "rails_admin_import", :git => "git://github.com/stephskardal/demo.git"

* Next, mount in your application by adding:

        mount RailsAdminImport::Engine => '/rails_admin_import', :as => 'rails_admin_import'" to config/routes

* Add to models that will be importable:

        ****

* Add to cancan to allow access to import:

        ****

Copyright
========

Copyright (c) 2011 End Point & Steph Skardal. See LICENSE.txt for further details.
