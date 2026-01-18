FactoryBot.define do
  factory :response do
    association :employee
    response_date { Faker::Date.between(from: 6.months.ago, to: Date.today) }

    # Likert scale fields (1-7, conforme dados do CSV)
    interest_in_position { rand(1..7) }
    contribution { rand(1..7) }
    learning_and_development { rand(1..7) }
    feedback { rand(1..7) }
    interaction_with_manager { rand(1..7) }
    career_opportunity_clarity { rand(1..7) }
    permanence_expectation { rand(1..7) }

    # eNPS (0-10)
    enps { rand(0..10) }

    # Comments (optional)
    interest_in_position_comment { rand < 0.3 ? Faker::Lorem.paragraph(sentence_count: 2) : nil }
    contribution_comment { rand < 0.3 ? Faker::Lorem.paragraph(sentence_count: 2) : nil }
    learning_and_development_comment { rand < 0.3 ? Faker::Lorem.paragraph(sentence_count: 2) : nil }
    feedback_comment { rand < 0.3 ? Faker::Lorem.paragraph(sentence_count: 2) : nil }
    interaction_with_manager_comment { rand < 0.3 ? Faker::Lorem.paragraph(sentence_count: 2) : nil }
    career_opportunity_clarity_comment { rand < 0.3 ? Faker::Lorem.paragraph(sentence_count: 2) : nil }
    permanence_expectation_comment { rand < 0.3 ? Faker::Lorem.paragraph(sentence_count: 2) : nil }
    enps_open_comment { rand < 0.5 ? Faker::Lorem.paragraph(sentence_count: 3) : nil }

    trait :promoter do
      enps { rand(9..10) }
      interest_in_position { rand(6..7) }
      contribution { rand(6..7) }
      learning_and_development { rand(6..7) }
      feedback { rand(6..7) }
      interaction_with_manager { rand(6..7) }
      career_opportunity_clarity { rand(6..7) }
      permanence_expectation { rand(6..7) }
    end

    trait :passive do
      enps { rand(7..8) }
      interest_in_position { 4 }
      contribution { 4 }
      learning_and_development { 4 }
      feedback { 4 }
      interaction_with_manager { 4 }
      career_opportunity_clarity { 4 }
      permanence_expectation { 4 }
    end

    trait :detractor do
      enps { rand(0..6) }
      interest_in_position { rand(1..3) }
      contribution { rand(1..3) }
      learning_and_development { rand(1..3) }
      feedback { rand(1..3) }
      interaction_with_manager { rand(1..3) }
      career_opportunity_clarity { rand(1..3) }
      permanence_expectation { rand(1..3) }
    end

    trait :highly_favorable do
      interest_in_position { 7 }
      contribution { 7 }
      learning_and_development { 7 }
      feedback { 7 }
      interaction_with_manager { 7 }
      career_opportunity_clarity { 7 }
      permanence_expectation { 7 }
      enps { 10 }
    end

    trait :unfavorable do
      interest_in_position { 1 }
      contribution { 1 }
      learning_and_development { 1 }
      feedback { 1 }
      interaction_with_manager { 1 }
      career_opportunity_clarity { 1 }
      permanence_expectation { 1 }
      enps { 0 }
    end

    trait :with_all_comments do
      interest_in_position_comment { Faker::Lorem.paragraph(sentence_count: 2) }
      contribution_comment { Faker::Lorem.paragraph(sentence_count: 2) }
      learning_and_development_comment { Faker::Lorem.paragraph(sentence_count: 2) }
      feedback_comment { Faker::Lorem.paragraph(sentence_count: 2) }
      interaction_with_manager_comment { Faker::Lorem.paragraph(sentence_count: 2) }
      career_opportunity_clarity_comment { Faker::Lorem.paragraph(sentence_count: 2) }
      permanence_expectation_comment { Faker::Lorem.paragraph(sentence_count: 2) }
      enps_open_comment { Faker::Lorem.paragraph(sentence_count: 3) }
    end

    trait :recent do
      response_date { rand(7..30).days.ago }
    end

    trait :old do
      response_date { rand(6..12).months.ago }
    end
  end
end
