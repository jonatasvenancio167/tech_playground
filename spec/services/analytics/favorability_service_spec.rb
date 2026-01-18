require 'rails_helper'

RSpec.describe Analytics::FavorabilityService, type: :service do
  describe '#calculate_dimension' do
    it 'computes favorability for a single dimension' do
      e1 = create(:employee)
      e2 = create(:employee)
      create(:response, employee: e1, interest_in_position: 6)
      create(:response, employee: e1, interest_in_position: 7)
      create(:response, employee: e2, interest_in_position: 1)
      create(:response, employee: e2, interest_in_position: 4)

      service = described_class.new(Response.all)
      result = service.calculate_dimension(:interest_in_position)

      expect(result[:total_count]).to eq(4)
      expect(result[:favorable_count]).to eq(2)
      expect(result[:unfavorable_count]).to eq(2)
      expect(result[:percentage]).to eq(50.0)
    end
  end

  describe '#calculate_all' do
    it 'returns favorability for all dimensions' do
      e = create(:employee)
      create(:response, employee: e,
             interest_in_position: 6,
             contribution: 6,
             learning_and_development: 5,
             feedback: 7,
             interaction_with_manager: 4,
             career_opportunity_clarity: 6,
             permanence_expectation: 3)

      service = described_class.new(Response.all)
      all = service.calculate_all

      expect(all.keys).to include(*Analytics::FavorabilityService::DIMENSIONS)
      expect(all[:interest_in_position][:percentage]).to be >= 0.0
      expect(all[:feedback][:percentage]).to be >= 0.0
    end
  end

  describe '#ranking' do
    it 'sorts dimensions by favorability percentage descending' do
      e = create(:employee)
      create(:response, employee: e,
             interest_in_position: 7,
             contribution: 6,
             learning_and_development: 1,
             feedback: 6,
             interaction_with_manager: 2,
             career_opportunity_clarity: 6,
             permanence_expectation: 3)

      service = described_class.new(Response.all)
      ranked = service.ranking

      expect(ranked.values.first[:percentage]).to be >= ranked.values.last[:percentage]
      expect(ranked).to be_a(Hash)
    end
  end

  describe '#overall_favorability' do
    it 'averages favorability across dimensions' do
      e = create(:employee)
      create(:response, employee: e,
             interest_in_position: 7,
             contribution: 6,
             learning_and_development: 6,
             feedback: 6,
             interaction_with_manager: 6,
             career_opportunity_clarity: 6,
             permanence_expectation: 6)

      service = described_class.new(Response.all)
      expect(service.overall_favorability).to be_between(0.0, 100.0)
    end
  end
end

