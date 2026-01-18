require 'rails_helper'

RSpec.describe 'Api::V1::Responses', type: :request do
  let(:headers) { { 'Accept' => 'application/json' } }

  before do
    @emp = create(:employee)
    create(:response, employee: @emp, response_date: 2.days.ago, enps: 9)
    create(:response, employee: @emp, response_date: 1.day.ago, enps: 5)
  end

  describe 'GET /api/v1/responses' do
    it 'returns serialized responses with pagination' do
      get '/api/v1/responses', headers: headers, params: { employee_id: @emp.id, page: 1, per_page: 10 }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']).to be_an(Array)
      expect(json['data'].first).to include('id', 'employee_id', 'response_date', 'enps')
      expect(json['meta']).to include('page', 'per_page', 'total')
    end

    it 'filters by date range' do
      get '/api/v1/responses', headers: headers, params: { date_from: 2.days.ago.to_date.to_s, date_to: Date.current.to_s }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data'].length).to be >= 2
    end
  end
end

