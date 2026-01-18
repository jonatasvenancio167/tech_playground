FactoryBot.define do
  factory :csv_import do
    file_name { "import_#{Faker::Alphanumeric.alphanumeric(number: 8)}.csv" }
    file_path { "/tmp/uploads/csv_imports/#{file_name}" }
    status { 'pending' }
    total_rows { 0 }
    processed_rows { 0 }
    employees_created { 0 }
    responses_created { 0 }
    import_errors { [] }

    trait :pending do
      status { 'pending' }
    end

    trait :processing do
      status { 'processing' }
      started_at { Time.current }
      total_rows { 100 }
      processed_rows { 50 }
    end

    trait :completed do
      status { 'completed' }
      started_at { 5.minutes.ago }
      completed_at { Time.current }
      total_rows { 100 }
      processed_rows { 100 }
      employees_created { 25 }
      responses_created { 100 }
    end

    trait :completed_with_errors do
      status { 'completed' }
      started_at { 5.minutes.ago }
      completed_at { Time.current }
      total_rows { 100 }
      processed_rows { 100 }
      employees_created { 20 }
      responses_created { 95 }
      import_errors do
        [
          { line: 15, employee: 'John Doe', error: 'Invalid email format' },
          { line: 32, employee: 'Jane Smith', error: 'Duplicate entry' },
          { line: 78, employee: 'Bob Wilson', error: 'Missing required field' }
        ]
      end
    end

    trait :failed do
      status { 'failed' }
      started_at { 2.minutes.ago }
      completed_at { Time.current }
      error_message { 'File not found or corrupted' }
    end

    trait :large_file do
      total_rows { 10_000 }
      processed_rows { 10_000 }
      employees_created { 2_500 }
      responses_created { 10_000 }
    end
  end
end
