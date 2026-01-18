require 'rails_helper'

RSpec.describe 'Api::V1::Analytics::Nps', type: :request do
  let(:headers) { { 'Accept' => 'application/json' } }

  before do
    create_list(:response, 3, :promoter)
    create_list(:response, 2, :passive)
    create_list(:response, 5, :detractor)
  end

  describe 'GET /api/v1/analytics/nps' do
    it 'returns NPS summary' do
      get '/api/v1/analytics/nps', headers: headers
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      data = json['data']['attributes']
      expect(data['total_responses']).to eq(10)
      expect(data['promoters']['count']).to eq(3)
      expect(data['detractors']['count']).to eq(5)
      expect(data['score']).to eq(-20.0)
    end
  end

  describe 'GET /api/v1/analytics/nps/distribution' do
    it 'returns distribution and summary' do
      get '/api/v1/analytics/nps/distribution', headers: headers
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      dist = json['data']['attributes']['distribution']
      expect(dist.length).to eq(11)
      total = dist.sum { |d| d['count'] }
      expect(total).to eq(Response.where.not(enps: nil).count)
      has_promoter_bin = dist.any? { |d| [9, 10].include?(d['score']) && d['count'] >= 1 }
      expect(has_promoter_bin).to be true
    end
  end

  describe 'GET /api/v1/analytics/nps/at_risk' do
    it 'returns at-risk departments structure' do
      get '/api/v1/analytics/nps/at_risk', headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['type']).to eq('at_risk_departments')
    end
  end
end
