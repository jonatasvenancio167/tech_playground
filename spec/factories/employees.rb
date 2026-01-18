FactoryBot.define do
  factory :employee do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    corporate_email { Faker::Internet.email(domain: 'company.com') }
    mobile_phone { Faker::PhoneNumber.cell_phone }
    department { Faker::Commerce.department }
    position { Faker::Job.title }
    function { Faker::Job.field }
    location { Faker::Address.city }
    company_tenure_months { rand(1..120) }
    gender { %w[Masculino Feminino Outro Prefiro\ não\ informar].sample }
    generation { %w[Baby\ Boomer Geração\ X Millennial Geração\ Z].sample }
    n0_company { "Tech Playground" }
    n1_directorate { Faker::Commerce.department }
    n2_management { "Gerência #{Faker::Commerce.department}" }
    n3_coordination { "Coordenação #{Faker::Commerce.department}" }
    n4_area { "Área #{Faker::Commerce.department}" }

    trait :with_responses do
      after(:create) do |employee|
        create_list(:response, 3, employee: employee)
      end
    end

    trait :without_responses do
      # Default - no responses
    end

    trait :engineering do
      department { "Engineering" }
      n1_directorate { "Technology" }
    end

    trait :sales do
      department { "Sales" }
      n1_directorate { "Commercial" }
    end

    trait :new_hire do
      company_tenure_months { rand(1..6) }
    end

    trait :veteran do
      company_tenure_months { rand(60..120) }
    end
  end
end
