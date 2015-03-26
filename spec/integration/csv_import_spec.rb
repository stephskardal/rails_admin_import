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

  describe "for a model with has_many" do
    # Add fixtures/people.yml to database
    fixtures :people

    it "import the associations" do
      file = fixture_file_upload("company.csv", "text/plain")
      post "/admin/company/import", file: file, import_format: 'csv',
        employees: 'email'
      expect(response).to be_success
      expect(Company.count).to eq 2

      employees = people(:person_one, :person_two)
      expect(Company.first.employees).to match_array employees

      employees = people(:person_three)
      expect(Company.second.employees).to match_array employees
    end
  end

  describe "for a namespaced model" do
    # Add fixtures/blog_authors.yml to database
    fixtures 'blog/authors'

    it "import the data" do
      file = fixture_file_upload("blog/posts.csv", "text/plain")
      post "/admin/blog~post/import", file: file, import_format: 'csv',
        authors: 'name'
      expect(response).to be_success
      expect(Blog::Post.count).to eq 2

      author = blog_authors(:author_one)
      expect(Blog::Post.first.authors).to contain_exactly author
    end
  end
end
