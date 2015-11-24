require "spec_helper"

describe "CSV import", :type => :request do
  describe "for a simple model" do
    it "imports the data" do
      file = fixture_file_upload("balls.csv", "text/plain")
      post "/admin/ball/import", file: file
      expect(response.body).not_to include "failed"
      expect(Ball.count).to eq 2
      expect(Ball.first.color).to eq "red"
    end

    describe "update_if_exists" do
      it "updates the records if they exist" do
        person = FactoryGirl.create(:person_one)

        file = fixture_file_upload("person_update.csv", "text/plain")
        post "/admin/person/import", file: file,
          "update_if_exists": "1",
          "update_lookup": "email",
          "associations[employee]": "name"

        expect(response.body).not_to include "failed"
        expect(Person.first.full_name).to match "John Snow"
        expect(Person.count).to eq 1
      end

      it "creates the records if they don't exist" do
        file = fixture_file_upload("person_update.csv", "text/plain")
        post "/admin/person/import", file: file,
          "update_if_exists": "1",
          "update_lookup": "email",
          "associations[employee]": "name"

        expect(response.body).not_to include "failed"
        expect(Person.first.full_name).to match "John Snow"
        expect(Person.count).to eq 1
      end
    end

    it "uses the configured object_label_method" do
      RailsAdmin.config do |config|
        config.model "Person" do
          object_label_method :full_name
        end
      end

      file = fixture_file_upload("person_update.csv", "text/plain")
      post "/admin/person/import", file: file,
        "associations[employee]": "name"

      expect(response.body).to include "John Snow"
    end
  end

  describe "for a model with belongs_to" do
    it "updates the record based on a association" do
      parent = FactoryGirl.create(:parent_one, id: "1")
      child = FactoryGirl.create(:child_one, parent: parent)

      file = fixture_file_upload("child_update.csv", "text/plain")
      post "/admin/child/import", file: file,
        "update_if_exists": "1",
        "update_lookup": "parent_id",
        "associations[parent]": "name"

      expect(response.body).not_to include "failed"
      expect(Child.first.name).to match "Tall One"
      expect(Child.count).to eq 1
    end
  end

  describe "for a model with has_many" do
    describe "for simple associations" do
      it "import the associations" do
        # Add children from support/associations.rb to the database
        children = create_children

        file = fixture_file_upload("parents.csv", "text/plain")
        post "/admin/parent/import", file: file,
          "associations[children]": 'name'
        expect(response.body).not_to include "failed"
        expect(Parent.count).to eq 2

        expected = children.slice(:child_one).values
        expect(Parent.first.children).to match_array expected

        expected = children.slice(:child_two, :child_three).values
        expect(Parent.offset(1).first.children).to match_array expected
      end
    end

    describe "for associations not found" do
      it "reports which assocations failed to be found" do
        # Don't add children from support/associations.rb to the database

        file = fixture_file_upload("parents.csv", "text/plain")
        post "/admin/parent/import", file: file, "associations[children]": 'name'
        expect(response.body).to include "failed"
        expect(Parent.count).to eq 0

        child_one_name = "One"
        child_two_name = "Two"
        expect(response.body).to include child_one_name
        expect(response.body).to include child_two_name
      end
    end

    describe "for associations with a different class name" do
      it "import the associations" do
        # Add people from support/associations.rb to the database
        people = create_people

        file = fixture_file_upload("company.csv", "text/plain")
        post "/admin/company/import", file: file,
          "associations[employees]": 'email'
        expect(response.body).not_to include "failed"
        expect(Company.count).to eq 2

        expected = people.slice(:person_one, :person_two).values
        expect(Company.first.employees).to match_array expected

        employees = people.slice(:person_three).values
        expect(Company.offset(1).first.employees).to match_array employees
      end
    end
  end

  describe "for a namespaced model" do
    it "import the data" do
      # Add authors from support/associations.rb to the database
      authors = create_blog_authors

      file = fixture_file_upload("blog/posts.csv", "text/plain")
      post "/admin/blog~post/import", file: file, "associations[authors]": 'name'
      expect(response.body).not_to include "failed"
      expect(Blog::Post.count).to eq 2

      expected = authors.slice(:author_one).values
      expect(Blog::Post.first.authors).to match_array expected
    end
  end

  describe "different character encoding" do
    it "detects encoding through auto-detection" do
      file = fixture_file_upload("shift_jis.csv", "text/plain")
      post "/admin/ball/import", file: file

      expect(response.body).not_to include "failed"
      expected = 
        ["Amazonギフト券5,000円分が抽選で当たる！CNN.co.jp 読者アンケートはこちらから",
         "「イノベーションに制度はいらない！」編集部による記事ピックアップで、新たな挑戦について考えませんか？",
         "高額・好条件のグローバル求人で年収800万円を目指しませんか？"]
      expect(Ball.all.map(&:color)).to match_array expected
    end

    it "decodes encoding when specified" do
      file = fixture_file_upload("latin1.csv", "text/plain")
      post "/admin/ball/import", file: file, encoding: 'ISO-8859-1'

      expect(response.body).not_to include "failed"
      expected = %w(
        Albâtre
        Améthyste
        Châtaigne
        Ébène
      )
      expect(Ball.all.map(&:color)).to match_array expected
    end
  end
end
