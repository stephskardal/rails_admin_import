require "spec_helper"
require "fileutils"

describe "Rails Admin Config" do
  shared_examples_for "a global config option" do |name, value|
    it "can be set with the old API" do
      expect {
        RailsAdminImport.config do |config|
          # config.logging = true
          config.public_send("#{name}=", value)
        end
      }.not_to raise_error
    end
    it "can be set with the new API" do
      expect {
        RailsAdmin.config do |config|
          config.configure_with :import do |config|
            # config.logging = true
            config.public_send("#{name}=", value)
          end
        end
      }.not_to raise_error
    end
  end

  describe "logging" do
    it_behaves_like "a global config option", "logging", true

    it "creates a log when importing", :type => :request do
      RailsAdmin.config do |config|
        config.configure_with :import do |config|
          config.logging = true
        end
      end

      expected_path = File.expand_path('../dummy_app/log/import', __FILE__)
      FileUtils.rm_rf expected_path

      file = fixture_file_upload("balls.csv", "text/plain")
      post "/admin/ball/import", params: { file: file }

      logfile = Dir.glob(File.join(expected_path, "*-import.csv"))
      expect(logfile).not_to be_empty
    end
  end

  describe "line_item_limit" do
    it_behaves_like "a global config option", "line_item_limit", 500

    it 'returns an error if the provided file exceeds the line limit', type: :request do
      RailsAdmin.config do |config|
        config.configure_with :import do |config|
          config.line_item_limit = 1
        end
      end

      file = fixture_file_upload('balls.csv', 'text/plain')
      post '/admin/ball/import', params: { file: file }
      expect(response.body).to include 'Please limit upload file to 1 line items.'
      expect(Ball.count).to eq 0
    end
  end

  describe "rollback_on_error" do
    it_behaves_like "a global config option", "rollback_on_error", true

    it "imports not record when one record fails to import", :type => :request,
      :if => (CI_ORM == :active_record) do
      RailsAdmin.config do |config|
        config.configure_with :import do |config|
          config.rollback_on_error = true
        end
      end

      file = fixture_file_upload("balls_error.csv", "text/plain")
      post "/admin/ball/import", params: { file: file }
      expect(response.body).to include "failed"
      expect(Ball.count).to eq 0
    end
  end

  describe "model" do
    context "with the new API" do
      describe "label" do
        it "can be set" do
          expect {
            RailsAdmin.config do |config|
              config.model "Ball" do
                object_label_method :color
              end
            end
          }.not_to raise_error
        end
      end

      describe "excluded fields" do
        it "can be set" do
          expect {
            RailsAdmin.config do |config|
              config.model "Person" do
                import do
                  include_all_fields
                  exclude_fields :first_name, :last_name
                end
              end
            end
          }.not_to raise_error
        end
      end
    end

    context "with the old API" do
      around do |example|
        silence_warnings { example.run }
      end

      describe "label" do
        it "can be set" do
          expect {
            RailsAdminImport.config do |config|
              config.model(Ball) do
                label :color
              end
            end
          }.not_to raise_error
        end
      end
      describe "excluded_fields" do
        it "can be set" do
          expect {
            RailsAdminImport.config do |config|
              config.model(Person) do
                excluded_fields [:first_name, :last_name]
              end
            end
          }.not_to raise_error
        end
      end

      describe "extra_fields" do
        it "can be set" do
          expect {
            RailsAdminImport.config do |config|
              config.model(Person) do
                extra_fields [:age]
              end
            end
          }.not_to raise_error
        end
      end
    end
  end
end
