Rails Admin Import functionality
========

Plugin functionality to add generic import to Rails Admin interface

Installation
========

* First, add to Gemfile:
    
        gem "rails_admin_import"

* If you are using cancan, add to ability.rb to specify which models can be imported:

        can :import, [User, Model1, Model2]

* Define configuration in config/initializers/rails_admin_import.rb:

        RailsAdmin.config do |config|
          # REQUIRED:
          # Include the import action
          config.actions do
            all
            import
          end
        
          # Optional:
          # Configure global RailsAdminImport options
          config.configure_with(:import) do |config|
            config.logging = true
          end
        
          # Optional:
          # Configure model-specific options using standard RailsAdmin DSL
          # See https://github.com/sferik/rails_admin/wiki/Railsadmin-DSL
          config.model 'User' do
            import do
              include_all_fields
              exclude_fields :secret_token
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

You could for example set an attribute on a Devise User model to skip checking for a password when importing a new model.

You could also download a file based on a URL from the import file and set a Paperclip file attribute on the model.

* "import" action must be added inside config.actions block in main application RailsAdmin configuration: config/initializers/rails_admin.rb.

        config.actions do
          ...
          import
          ...
        end

  Refer to [RailAdmin documentation on custom actions](https://github.com/sferik/rails_admin/wiki/Actions) that must be present in this block.


* TODO: Right now, import doesn't work for fields ending in s, because inflector fails in models ending in s singularly. Belongs_to and many
  mapping needs to be updated to use klasses instead of symbols

* TODO: Verify that this works. To change a model configuration for all models, do

```
RailsAdmin.config do |config|
  ActiveRecord::Base.descendants.each do |imodel|
    config.model "#{imodel}" do
      import do
        exclude_fields :versions
      end
    end
  end
end
```

* TODO: should have_many relations use the singular or plural version of the column header?


Run tests
=========

1. Clone the repository to your machine

    git clone https://github.com/stephskardal/rails_admin_import
    
2. Run `bundle install`
3. Run `rspec`


Authors
=======

Original author: [Steph Skardal](https://github.com/stephskardal)

Maintainer (since May 2015): [Julien Vanier](https://github.com/monkbroc)


Copyright
========

Copyright (c) 2015 End Point, Steph Skardal and contributors. See LICENSE.txt for further details.
