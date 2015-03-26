require "spec_helper"

describe "CSV import", :type => :request do
  describe "for a simple model" do
    it "imports the data" do
      file = fixture_file_upload("balls.csv", "text/plain")
      post "/admin/ball/import", file: file, import_format: 'csv'
      expect(response).to be_success
      expect(Ball.count).to eq 2
      expect(Ball.first.color).to eq "red"
    end
  end

  describe "for a model with belongs_to" do
    # Add fixtures/people.yml to database
    fixtures :people

    it "import the associations" do
      file = fixture_file_upload("company.csv", "text/plain")
      post "/admin/company/import", file: file, import_format: 'csv',
        employees: 'email'
      expect(response).to be_success
      expect(Company.count).to eq 1
      employees = people(:person_one, :person_two)
      expect(Company.first.employees).to match_array employees
    end
  end
end
