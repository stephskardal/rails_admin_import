## Rails Admin Import Test App

This test app is mostly copied from the [Rails Admin test app](https://github.com/sferik/rails_admin/tree/master/spec/dummy_app).

Install gems with `bundle install`

Setup the database with `RAILS_ENV=test rake db:setup`

To run it with ActiveRecord run `CI_ORM=active_record rails s`

To run it with Mongoid run `CI_ORM=mongoid rails s`
