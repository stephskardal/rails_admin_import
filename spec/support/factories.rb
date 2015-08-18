FactoryGirl.define do
  factory :child do
    factory :child_one do
      name "One"
    end

    factory :child_two do
      name "Two"
    end

    factory :child_three do
      name "Three"
    end
  end

  factory :parent do
    factory :parent_one do
      name "One"
    end

    factory :parent_two do
      name "Two"
    end
  end

  factory :person do
    factory :person_one do
      first_name "Person"
      last_name "One"
      email "one@example.com"
    end

    factory :person_two do
      first_name "Person"
      last_name "Two"
      email "two@example.com"
    end

    factory :person_three do
      first_name "Person"
      last_name "Three"
      email "three@example.com"
    end
  end

  factory :blog_author, :class => Blog::Author do
    factory :author_one do
      name "Author One"
    end
  end
end

