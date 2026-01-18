require 'rails_helper'

RSpec.describe 'Api::V1::Analytics::Dashboard', type: :request do
  let(:headers) { { 'Accept' => 'application/json' } }

  before do
    eng = create(:employee, department: 'Engineering')
    mkt = create(:employee, department: 'Marketing')
    create(:response, :promoter, employee: eng, response_date: Date.current)
    create(:response, :detractor, employee: mkt, response_date: Date.current)
  end

  describe 'GET /api/v1/analytics/dashboard' do
    it 'returns company overview' do
      get '/api/v1/analytics/dashboard', headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      attrs = json['data']['attributes']
      expect(attrs).to have_key('participation')
      expect(attrs).to have_key('enps')
      expect(attrs).to have_key('favorability')
      expect(attrs).to have_key('demographics')
    end
  end

  describe 'GET /api/v1/analytics/dashboard/departments' do
    it 'returns department breakdown' do
      get '/api/v1/analytics/dashboard/departments', headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      list = json['data']['attributes']['departments']
      expect(list).to be_an(Array)
      expect(list.first).to have_key('department')
      expect(list.first).to have_key('enps')
    end
  end
end

