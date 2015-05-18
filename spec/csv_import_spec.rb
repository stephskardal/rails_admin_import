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
  end

  describe "for a model with has_many" do
    describe "for simple associations" do
      # Add fixtures/children.yml to database
      fixtures :children

      it "import the associations" do
        file = fixture_file_upload("parents.csv", "text/plain")
        post "/admin/parent/import", file: file, children: 'name'
        expect(response.body).not_to include "failed"
        expect(Parent.count).to eq 2

        children = children(:child_one)
        expect(Parent.first.children).to match_array children

        children = children(:child_two, :child_three)
        expect(Parent.second.children).to match_array children
      end
    end

    describe "for associations not found" do
      # Don't import fixtures/children.yml to the database

      it "reports which assocations failed to be found" do
        file = fixture_file_upload("parents.csv", "text/plain")
        post "/admin/parent/import", file: file, children: 'name'
        expect(response.body).to include "failed"
        expect(Parent.count).to eq 0

        child_one_name = "One"
        child_two_name = "Two"
        expect(response.body).to include child_one_name
        expect(response.body).to include child_two_name
      end
    end

    describe "for associations with a different class name" do
      # Add fixtures/people.yml to database
      fixtures :people

      it "import the associations" do
        file = fixture_file_upload("company.csv", "text/plain")
        post "/admin/company/import", file: file, employees: 'email'
        expect(response.body).not_to include "failed"
        expect(Company.count).to eq 2

        employees = people(:person_one, :person_two)
        expect(Company.first.employees).to match_array employees

        employees = people(:person_three)
        expect(Company.second.employees).to match_array employees
      end
    end
  end

  describe "for a namespaced model" do
    # Add fixtures/blog_authors.yml to database
    fixtures 'blog/authors'

    it "import the data" do
      file = fixture_file_upload("blog/posts.csv", "text/plain")
      post "/admin/blog~post/import", file: file, authors: 'name'
      expect(response.body).not_to include "failed"
      expect(Blog::Post.count).to eq 2

      author = blog_authors(:author_one)
      expect(Blog::Post.first.authors).to contain_exactly author
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
