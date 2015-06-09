require "spec_helper"

describe "JSON import", :type => :request do
  describe "for a simple model" do
    context "with the data in an array" do
      it "imports the data" do
        file = fixture_file_upload("balls.json", "text/plain")
        post "/admin/ball/import", import_format: 'json', file: file
        expect(response.body).not_to include "failed"
        expect(Ball.count).to eq 2
        expect(Ball.first.color).to eq "red"
      end
    end

    context "with the data in an object with a root key" do
      it "imports the data" do
        file = fixture_file_upload("balls_with_root.json", "text/plain")
        post "/admin/ball/import", import_format: 'json', file: file
        expect(response.body).not_to include "failed"
        expect(Ball.count).to eq 2
        expect(Ball.first.color).to eq "red"
      end
    end
  end

  describe "for a model with has_many" do
    describe "for simple associations" do
      it "import the associations" do
        # Add children from support/associations.rb to the database
        children = create_children

        file = fixture_file_upload("parents.json", "text/plain")
        post "/admin/parent/import", import_format: 'json', file: file, "associations[children]": 'name'
        expect(response.body).not_to include "failed"
        expect(Parent.count).to eq 2

        expected = children.slice(:child_one).values
        expect(Parent.first.children).to match_array expected

        expected = children.slice(:child_two, :child_three).values
        expect(Parent.offset(1).first.children).to match_array expected
      end
    end
  end
end

