def create_children
  {
    :child_one => FactoryBot.create(:child_one),
    :child_two => FactoryBot.create(:child_two),
    :child_three => FactoryBot.create(:child_three)
  }
end

def create_people
  {
    :person_one => FactoryBot.create(:person_one),
    :person_two => FactoryBot.create(:person_two),
    :person_three => FactoryBot.create(:person_three)
  }
end

def create_blog_authors
  {
    :author_one => FactoryBot.create(:author_one)
  }
end
