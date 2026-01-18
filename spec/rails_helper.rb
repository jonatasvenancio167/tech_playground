# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'

# Set DATABASE_URL for test environment if not already set
ENV['DATABASE_URL'] ||= 'postgres://postgres:postgres@db:5432/app_test'

require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'shoulda/matchers'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories.
Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # Use transactional fixtures
  config.use_transactional_fixtures = true

  # Set ActiveJob queue adapter to :test for job specs
  config.before(:each, type: :job) do
    ActiveJob::Base.queue_adapter = :test
  end

  # Infer spec type from file location
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces
  config.filter_rails_from_backtrace!

  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods

  # Include ActiveJob test helpers
  config.include ActiveJob::TestHelper, type: :job

  # Include time helpers for freeze_time, travel_to, etc.
  config.include ActiveSupport::Testing::TimeHelpers

  # Run specs in random order
  config.order = :random

  # Seed global randomization
  Kernel.srand config.seed

  # Clear Faker unique values between tests
  config.before(:each) do
    Faker::UniqueGenerator.clear
  end
end

# Configure Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
