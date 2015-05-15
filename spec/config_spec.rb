require "spec_helper"

describe "Rails Admin Config", :reset_config => true do
  describe "logging" do
    it "can be set" do
      expect {
        RailsAdminImport.config do |config|
          config.logging = true
        end
      }.not_to raise_error
    end
  end

  describe "line_item_limit" do
    it "can be set" do
      expect {
        RailsAdminImport.config do |config|
          config.line_item_limit = 500
        end
      }.not_to raise_error
    end
  end

  describe "model" do
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
