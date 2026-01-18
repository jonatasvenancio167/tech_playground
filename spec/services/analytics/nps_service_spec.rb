require 'rails_helper'

RSpec.describe Analytics::NpsService, type: :service do
  describe '#calculate' do
    it 'computes NPS metrics and level' do
      create_list(:response, 3, :promoter)
      create_list(:response, 2, :passive)
      create_list(:response, 5, :detractor)

      service = described_class.new(Response.all)
      result = service.calculate

      expect(result[:total_responses]).to eq(10)
      expect(result[:promoters][:count]).to eq(3)
      expect(result[:passives][:count]).to eq(2)
      expect(result[:detractors][:count]).to eq(5)
      expect(result[:score]).to eq(-20.0)
      expect(result[:level]).to eq('critical')
    end
  end

  describe '#distribution' do
    it 'returns counts per score from 0 to 10' do
      create(:response, enps: 0)
      create(:response, enps: 7)
      create(:response, enps: 9)

      service = described_class.new(Response.all)
      dist = service.distribution

      expect(dist.length).to eq(11)
      expect(dist.find { |d| d[:score] == 0 }[:count]).to eq(1)
      expect(dist.find { |d| d[:score] == 7 }[:count]).to eq(1)
      expect(dist.find { |d| d[:score] == 9 }[:count]).to eq(1)
    end
  end
end

