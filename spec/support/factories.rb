FactoryBot.define do
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

    factory :person_jane_doe do
      first_name "Jane"
      last_name "Doe"
      email "jane.doe@example.com"
    end

    factory :person_jane_smith do
      first_name "Jane"
      last_name "Smith"
      email "jane.smith@example.com"
    end
  end

  factory :blog_author, :class => Blog::Author do
    factory :author_one do
      name "Author One"
    end
  end
end

