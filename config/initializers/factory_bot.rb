# Configure FactoryBot to load factories from spec/factories
if defined?(FactoryBot)
  FactoryBot.definition_file_paths = [Rails.root.join('spec/factories')]
end
