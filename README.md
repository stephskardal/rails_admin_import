# Rails Admin Import

[![Build Status](https://travis-ci.org/monkbroc/rails_admin_import.svg?branch=master)](https://travis-ci.org/monkbroc/rails_admin_import)

Plugin functionality to add generic import to Rails Admin from CSV, JSON and XLSX files

## Installation

* First, add to Gemfile:

```
gem "rails_admin_import", "~> 2.2"
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
  # Configure pass filename to records hashes
  config.configure_with(:import) do |config|
    config.logging = true
    config.pass_filename = true
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
cannot :import, :all
can :import, [User, Model1, Model2]
```

## Usage

Model instances can be both created and updated from import data. Any fields
can be imported as long as they are allowed by the model's configuration.
Associated records can be looked up for both singular and plural relationships.
Both updating existing records and associating records requires the use of
**mapping keys**.

### Mapping Keys

Every importable class has a mapping key that uniquely identifies its
instances. The mapping key can be one or more fields. The value for
these fields can then be provided in import data, either to update the
existing record or to attach it through an association to another model.
This concept exists because `id`s are often not constant when moving
records between data stores.

For example, a `User` model may have an `email` field. When uploading a set
of users where some already exist in our database, we can select "email" as
our mapping key and then provide that field on each record in our data,
allowing us to update existing records with matching emails.

Using a csv formatted example:
```
Email,First name,Last name
peter.gibbons@initech.com,Peter,Gibbons
michael.bolton@initech.com,Michael,Bolton
```
would look for existing users with those emails. If one was found, its name
fields would be updated. Otherwise, a new one would be created.

For updating building owners, the mapping key could be `street_address` and
`zip_code`.

Similarly, if each user has favorite books, we could set the mapping key
for `Book` to be `isbn` and then include the isbn for their books within each
user record. The syntax for this is to use the name of the associated model as
the field name, no matter what actual mapping key has been selected. So
a user record would have one or more fields named "Book" that include each
associated book's ISBN.

Again using a csv formatted example:
```
Email, Book, Book, Book
peter.gibbons@initech.com, 9781119997870, 9780671027032
michael.bolton@initech.com, 9780446677479
```
would look up books with those ISBNs and attach them to those users.

Mapping keys can be selected on the import page. Their defaults can also be
globally configured in the config file:

```
RailsAdmin.config do |config|
  config.model 'User' do
    import do
      mapping_key :email
      # for multiple values, use mapping_key [:first_name, :last_name]
      mapping_key_list [:email, :some_other_id]
    end
  end
end
```

Since in models with large number of fields it doesn't make sense to use
most of them as mapping values, you can add `mapping_key_list` to
restrict which fields can be selected as mapping key in the UI during import.

Note that a matched record must exist when attaching associated models, or the
imported record will fail and be skipped.

Complex associations (`has_one ..., :through` or polymorphic associations)
need to be dealt with via custom logic called by one of the import hooks
(see below for more detail on using hooks).  If we wanted to import
`Service`s and attach them to a `User`, but the user relationship
existed through an intermediary model called `ServiceProvider`, we could
provide a `user_email` field in our records and handle the actual
association with an import hook:

```
class Service < ActiveRecord::Base
  belongs_to :service_provider
  has_one :user, through: :service_provider

  def before_import_save(record)
    if (email = record[:user_email]) && (user = User.find_by_email(email))
      self.service_provider = user.service_provider
    end
  end
end
```

Importing new records by id is not recommended since it ignores the sequences of ids in database. That will lead to `ERROR: duplicate key value violates unique constraint` in future. You can work around this issue by adding an `import_id` column to your model, renaming the `id` column in your CSV to `import_id` and using `import_id` as the update lookup field.

### File format

The format is inferred by the extension (.csv, .json or .xlsx).

#### CSV

The first line must contain attribute names. They will be converted to lowercase and underscored (First Name ==> first_name).

For "many" associations, you may include multiple columns with the same header in the CSV file.

The repeated header may be singular or plural. For example, for a "children" association, you may have multiple "child" columns or multiple "children" column, each containing one lookup value for an associated record. Blank values are ignored.

Example

```
First name,Last name,Team,Team
Peter,Gibbons,IT,Management
Michael,Bolton,IT,
```

Blank lines will be skipped.

#### JSON

The file must be an array or an object with a root key the same name as the plural model name, i.e. the default Rails JSON output format with include_root_in_json on or off.

#### XLSX

The Microsoft Excel XLM format (XLSX) is supported, but not the old binary Microsoft Excel format (XLS).

The expected rows and columns are the same as for the CSV format (first line contains headers, multiple columns for "many" associations).

Blank lines will be skipped.

## Configuration

### Global configuration options

```ruby
RailsAdmin.config do |config|
  config.actions do
    all
    import
  end

  # Default global RailsAdminImport options
  config.configure_with(:import) do |config|
    config.logging = false
    config.line_item_limit = 1000
    config.update_if_exists = false
    config.pass_filename = false
    config.rollback_on_error = false
    config.header_converter = lambda do |header|
      # check for nil/blank headers
      next if header.blank?
      header.parameterize.underscore
    end
    config.csv_options = {}
  end
end
```

* __logging__ (default `false`): Save a copy of each imported file to log/import and a detailed import log to log/rails_admin_import.log

* __line_item_limit__ (default `1000`): max number of items that can be imported at one time.

* __update_if_exists__ (default `false`): default value for the "Update if exists" checkbox on the import page.

* __rollback_on_error__ (default `false`): import records in a transaction and rollback if there is one error. Only for ActiveRecord, not Mongoid.

* __header_converter__ (default `lambda { ... }`): a lambda to convert each CSV header text string to a model attribute name. The default header converter converts to lowercase and replaces spaces with underscores.

* __csv_options__ (default `{}`): a hash of options that will be passed to a new [CSV](http://ruby-doc.org/stdlib-2.0.0/libdoc/csv/rdoc/CSV.html) instance
* __pass_filename__ (default `false`): Access the uploaded file name in your model actions, for example if set to true, inside each record, there will be an addtional property `record[:filename_importer]` which contains the file name of the currently uploaded file.

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

* To overwrite the [default excluded fields](https://github.com/stephskardal/rails_admin_import/blob/master/lib/rails_admin_import/config/sections/import.rb#L13) and allow matching to `:id` on import

```ruby
RailsAdmin.config do |config|
  config.model 'User' do
    import do
      default_excluded_fields [:created_at, :updated_at, :deleted_at, :c_at, :u_at]
    end
  end
end
```

## Import hooks

Define methods on your models to be hooked into the import process, if special/additional processing is required on the data:

```ruby
# some model
class User < ActiveRecord::Base
  def self.before_import
    # called on the model class once before importing any individual records
  end

  def self.before_import_find(record)
    # called on the model class before finding or creating the new record
    # maybe modify the import record that will be used to find the model
    # throw :skip to skip importing this record
    throw :skip unless record[:email].ends_with? "@mycompany.com"
  end

  def before_import_attributes(record)
    # called on the blank new model or the found model before fields are imported
    # maybe delete fields from the import record that you don't need
    # throw :skip to skip importing this record
  end

  def before_import_associations(record)
    # called on the model with attributes but before associations are imported
    # do custom import of associations
    # make sure to delete association fields from the import record to avoid double import
    record.delete(:my_association)
    # throw :skip to skip importing this record
  end

  def before_import_save(record)
    # called on the model before it is saved but after all fields and associations have been imported
    # make final modifications to the record
    # throw :skip to skip importing this record
  end

  def after_import_save(record)
    # called on the model after it is saved
  end

  def after_import_association_error(record)
    # called on the model when an association cannot be found
  end

  def after_import_error(record)
    # called on the model when save fails
  end

  def self.after_import
    # called once on the model class after importing all individual records
  end
end
```

For example, you could

* Set an attribute on a Devise User model to skip checking for a password when importing a new model.

* Import an image into Carrierwave via a URL provided in the CSV.

```
def before_import_save(record)
  self.remote_image_url = record[:image] if record[:image].present?  
end
```

* Skip some validations when importing.

```
class User < ActiveRecord::Base
  # Non-persistent attribute to allow creating a new user without a password
  # Password will be set by the user by following a link in the invitation email
  attr_accessor :allow_blank_password

  devise :validatable

  # Called by Devise to enable/disable password presence validation
  def password_required?
    allow_blank_password ? false : super
  end

  # Don't require a password when importing users
  def before_import_save(record)
    self.allow_blank_password = true
  end
end
```


## ORM: ActiveRecord and Mongoid

The gem is tested to work with ActiveRecord and Mongoid.

Support for Mongoid is early, so if you can suggest improvements (especially around importing embedded models), open an issue.


## Eager loading

Since the import functionality is rarely used in many applications, some gems are autoloaded when first used during an import in order to save memory at boot.

If you prefer to eager load all dependecies at boot, use this line in your `Gemfile`.

```
gem "rails_admin_import", "~> 1.2.0", require: "rails_admin_import/eager_load"
```

## Import error due to Rails class reloading

![error due to class reloading](https://user-images.githubusercontent.com/2566348/51355874-0f83ad00-1a7e-11e9-8e58-46bc4699f2e6.jpg)

If you get an error like `Error during import: MyModel(#70286054976500) expected, got MyModel(#70286114743280)`, you need restart the rails server and redo the import. This is due to the fact that Rails reloads the ActiveRecord model classes in development when you make changes to them and Rails Admin is still using the old class.

Another suggestion is to set `config.cache_classes = true` to true in your `development.rb` for Rails Admin Import to work around the ActiveRecord model class reloading issue. See [this comment](https://github.com/stephskardal/rails_admin_import/issues/88#issuecomment-455374671) for more information.

## Customize the UI

If you want to hide all the advanced fields from the import UI, you can copy [`app/views/rails_admin/main/import.html.haml`](app/views/rails_admin/main/import.html.haml) to your project at the same path. Add `.hidden` at the end of lines you want to hide.

For example:
```
    .form-group.control-group.hidden
      %label.col-sm-2.control-label= t("admin.import.update_if_exists")
      .col-sm-10.controls
        = check_box_tag :update_if_exists, '1', true, :class => "form-control"
        %p.help-block= t('admin.import.help.update_if_exists')
```

## Upgrading

* Move global config to `config.configure_with(:import)` in `config/initializers/rails_admin_import.rb`.

* Move the field definitions to `config.model 'User' do; import do; // ...` in `config/initializers/rails_admin_import.rb`.

* No need to mount RailsAdminImport in `config/routes.rb` (RailsAdmin must still be mounted).

* Update model import hooks to take 1 hash argument instead of 2 arrays with values and headers.

* Support for importing file attributes was removed since I couldn't understand how it works. It should be possible to reimplement it yourself using post import hooks. Open an issue to discuss how to put back support for importing files into the gem.

## Community-contributed translations

* [Spanish translation](https://gist.github.com/yovasx2/dc0e9512e6c6243f840c) by Giovanni Alberto

* [French translation](https://github.com/rodinux/rails_admin_import.fr-MX.yml) by Rodolphe Robles. (I suggest to translate also rails admin.fr and your locales.fr to resolve an issue with DatePicker)

* [Italian translation](https://gist.github.com/aprofiti/ec3dc452898c8c48534b59eeb2701765) by Alessandro Profiti

* [Japanese translation](https://gist.github.com/higumachan/c4bf669d6446ec509386229f916ba5fc) by Yuta Hinokuma

* [Brazilian Portuguese translation](https://gist.github.com/tteurs/5a87ff4bc5f24692dab05b3cde0ca9df) by Matheo Gracia Pegoraro

## Run tests

1. Clone the repository to your machine

    git clone https://github.com/stephskardal/rails_admin_import

2. Run `bundle install`
3. Run `bundle exec rspec`

The structure of the tests is taken from the Rails Admin gem.

## Authors

Original author: [Steph Skardal](https://github.com/stephskardal)

Maintainer (since May 2015): [Julien Vanier](https://github.com/monkbroc)


## Release

- Update `lib/rails_admin_import/version.rb`
- Update the install instructions at [the top of the readme](#installation)
- Commit to git
- `rake release`

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/stephskardal/rails_admin_import/issues)
- Fix bugs and [submit pull requests](https://github.com/stephskardal/rails_admin_import/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

## Copyright

Copyright (c) 2015 End Point, Steph Skardal and contributors. See LICENSE.txt for further details.
