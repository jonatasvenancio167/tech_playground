require 'rails_helper'

RSpec.describe 'Api::V1::Analytics::Favorability', type: :request do
  let(:headers) { { 'Accept' => 'application/json' } }

  before do
    e1 = create(:employee, department: 'Engineering', location: 'São Paulo', corporate_email: nil)
    e2 = create(:employee, department: 'Marketing', location: 'Rio de Janeiro', corporate_email: nil)
    create(:response, employee: e1, interest_in_position: 7, feedback: 6, contribution: 6)
    create(:response, employee: e2, interest_in_position: 3, feedback: 2, contribution: 4)
  end

  describe 'GET /api/v1/analytics/favorability' do
    it 'returns favorability metrics' do
      get '/api/v1/analytics/favorability', headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      attrs = json['data']['attributes']
      expect(attrs['dimensions']).to be_a(Hash)
      expect(attrs['overall']).to be_a(Float)
      expect(attrs['ranking']).to be_a(Hash)
    end
  end

  describe 'GET /api/v1/analytics/favorability/by_department' do
    it 'returns aggregated metrics per department' do
      get '/api/v1/analytics/favorability/by_department', headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      departments = json['data']['attributes']['departments']
      expect(departments).to be_a(Hash)
      expect(departments.keys).to include('engineering', 'marketing')
    end
  end
end
