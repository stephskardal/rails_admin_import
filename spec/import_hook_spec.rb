require "spec_helper"

describe "Import hook", :type => :request do
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
