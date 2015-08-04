# Rails Admin Import

[![Build Status](https://travis-ci.org/monkbroc/rails_admin_import.svg?branch=master)](https://travis-ci.org/monkbroc/rails_admin_import)

Plugin functionality to add generic import to Rails Admin from CSV and JSON files

*This Readme is for version 1.0. If you are still using version 0.1.x, see [this branch](https://github.com/stephskardal/rails_admin_import/tree/legacy)*

## Installation

* First, add to Gemfile:

```
gem "rails_admin_import", "~> 1.0.0"
```

* Define configuration in `config/initializers/rails_admin_import.rb`:

```ruby
RailsAdmin.config do |config|
  # REQUIRED:
  # Include the import action
  # See https://github.com/sferik/rails_admin/wiki/Actions
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
```

* If you are using CanCanCan for authorization, add to ability.rb to specify which models can be imported:

```ruby
can :import, [User, Model1, Model2]
```

## File format

### CSV

The first line must contain attribute names. They will be converted to lowercase and underscored (First Name ==> first_name).

For "many" associations, you may include multiple columns with the same header in the CSV file.

The repeated header may be singular or plural. For example, for a "children" association, you may have multiple "child" columns or multiple "children" column, each containing one lookup value for an associated record. Blank values are ignored.

Example

```
First name,Last name,Team,Team
Peter,Gibbons,IT,Management
Michael,Bolton,IT,
```

### JSON

The file must be an array or an object with a root key the same name as the plural model name, i.e. the default Rails JSON output format with include_root_in_json on or off.


## Configuration

### Global configuration options

* __logging__ (default `false`): Save a copy of each imported file to log/import and a detailed import log to log/rails_admin_import.log

* __line_item_limit__ (default `1000`): max number of items that can be imported at one time. TODO: Currently this is suggested but not enforced.

* __rollback_on_error__ (default `false`): import records in a transaction and rollback if there is one error. Only for ActiveRecord, not Mongoid.

* __header_converter__ (default `nil`): a lambda to convert each CSV header text string to a model attribute name. The default header converter converts to lowercase and replaces spaces with underscores.

* __csv_options__ (default `{}`): a hash of options that will be passed to a new [CSV](http://ruby-doc.org/stdlib-2.0.0/libdoc/csv/rdoc/CSV.html) instance

### Model-specific configuration

Use [standard RailsAdmin DSL](https://github.com/sferik/rails_admin/wiki/Railsadmin-DSL) to add or remove fields.

* To change the default attribute that will be used to find associations on import, set `mapping_key` (default attribute is `name`)

```ruby
RailsAdmin.config do |config|
  config.model 'Ball' do
    import do
      mapping_key :color
    end
  end
end
```

* To include a specific list of fields:

```ruby
RailsAdmin.config do |config|
  config.model 'User' do
    import do
      field :first_name
      field :last_name
      field :email
    end
  end
end
```

* To exclude specific fields:

```ruby
RailsAdmin.config do |config|
  config.model 'User' do
    import do
      include_all_fields
      exclude_fields :secret_token
    end
  end
end
```

* To add extra fields that will be set as attributes on the model and that will be passed to the import hook methods:

```ruby
RailsAdmin.config do |config|
  config.model 'User' do
    import do
      include_all_fields
      fields :special_import_token
    end
  end
end
```

## Import hooks


Define instance methods on your models to be hooked into the import process, if special/additional processing is required on the data:

```ruby
# some model
class User < ActiveRecord::Base
  def before_import_save(record)
    # Your custom special sauce
  end

  def after_import_save(record)
    # Your custom special sauce
  end
end
```

For example, you could

* Set an attribute on a Devise User model to skip checking for a password when importing a new model.

* Download a file based on a URL from the import file and set a Paperclip file attribute on the model.


## ORM: ActiveRecord and Mongoid

The gem is tested to work with ActiveRecord and Mongoid.

Support for Mongoid is early, so if you can suggest improvements (especially around importing embedded models), open an issue.


## Upgrading

* Move global config to `config.configure_with(:import)` in `config/initializers/rails_admin_import.rb`.

* Move the field definitions to `config.model 'User' do; import do; // ...` in `config/initializers/rails_admin_import.rb`.

* No need to mount RailsAdminImport in `config/routes.rb` (RailsAdmin must still be mounted).

* Update model import hooks to take 1 hash argument instead of 2 arrays with values and headers.

* Support for importing file attributes was removed since I couldn't understand how it works. It should be possible to reimplement it yourself using post import hooks. Open an issue to discuss how to put back support for importing files into the gem.

## Run tests

1. Clone the repository to your machine

    git clone https://github.com/stephskardal/rails_admin_import

2. Run `bundle install`
3. Run `rspec`

The structure of the tests is taken from the Rails Admin gem.

## Authors

Original author: [Steph Skardal](https://github.com/stephskardal)

Maintainer (since May 2015): [Julien Vanier](https://github.com/monkbroc)


## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/blazer/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/blazer/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

## Copyright

Copyright (c) 2015 End Point, Steph Skardal and contributors. See LICENSE.txt for further details.
