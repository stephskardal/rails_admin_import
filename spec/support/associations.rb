def create_children
  {
    :child_one => FactoryGirl.create(:child_one),
    :child_two => FactoryGirl.create(:child_two),
    :child_three => FactoryGirl.create(:child_three)
  }
end

def create_people
  {
    :person_one => FactoryGirl.create(:person_one),
    :person_two => FactoryGirl.create(:person_two),
    :person_three => FactoryGirl.create(:person_three)
  }
end

def create_blog_authors
  {
    :author_one => FactoryGirl.create(:author_one)
  }
end
