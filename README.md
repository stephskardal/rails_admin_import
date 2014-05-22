Request for Contributors / Core Contributors
========

I apologize for my extreme lack of attention to this repository since it was created. I see that several users have forked this gem and applied updates. I'd be interested in giving access to this main repository for any interested in maintaining it and/or adding features. Please contact me if you are interested at steph at endpoint dot com. 


Rails Admin Import functionality
========

Plugin functionality to add generic import to Rails Admin interface

Installation
========

* First, add to Gemfile:
    
        gem "rails_admin_import"

* Next, mount in your application by adding following line to your config/routes.rb:

        mount RailsAdminImport::Engine => '/rails_admin_import', :as => 'rails_admin_import'

* If you are using cancan, add to ability.rb to specify which models can be imported:

        can :import, [User, Model1, Model2]

* Define configuration in config/initializers/rails_admin_import.rb:

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
          # Your custom special sauce          
        end

        def after_import_save(row, map)
          # Your custom special sauce          
        end

* "import" action must be added inside config.actions block in main application RailsAdmin configuration: config/initializers/rails_admin.rb.

        config.actions do
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

Copyright (c) 2014 End Point & Steph Skardal. See LICENSE.txt for further details.
