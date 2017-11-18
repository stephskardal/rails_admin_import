require "spec_helper"

describe "Import hook", :type => :request do
  describe "before_import_save" do
    it "is called" do
      # Add people from support/associations.rb to the database
      people = create_people

      file = fixture_file_upload("company.csv", "text/plain")
      post "/admin/company/import", file: file,
        "associations[employees]": 'email'

      # Company.before_import_save sets source to "import"
      expect(Company.first.source).to eq "import"
    end
  end

  describe "before_import_find" do
    it "skips import when it returns false" do
      # Add people from support/associations.rb to the database
      people = create_people

      file = fixture_file_upload("company_skip.csv", "text/plain")
      post "/admin/company/import", file: file,
        "associations[employees]": 'email'

      expect(Company.count).to eq 1
    end
  end
end
