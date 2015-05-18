require "spec_helper"

describe "JSON import", :type => :request do
  describe "for a simple model" do
    it "imports the data" do
      file = fixture_file_upload("balls.json", "text/plain")
      post "/admin/ball/import", import_format: 'json', file: file
      expect(response.body).not_to include "failed"
      expect(Ball.count).to eq 2
      expect(Ball.first.color).to eq "red"
    end
  end

  describe "for a model with has_many" do
    describe "for simple associations" do
      # Add fixtures/children.yml to database
      fixtures :children

      it "import the associations" do
        file = fixture_file_upload("parents.json", "text/plain")
        post "/admin/parent/import", import_format: 'json', file: file, "associations[children]": 'name'
        expect(response.body).not_to include "failed"
        expect(Parent.count).to eq 2

        children = children(:child_one)
        expect(Parent.first.children).to match_array children

        children = children(:child_two, :child_three)
        expect(Parent.second.children).to match_array children
      end
    end
  end
end

