require 'rails_helper'

RSpec.describe 'Dashboards', type: :request do
  before do
    e = create(:employee, department: 'engineering')
    create(:response, :promoter, employee: e, response_date: Date.current)
  end

  describe 'GET /' do
    it 'renders index' do
      get '/'
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /dashboards/company' do
    it 'renders company dashboard' do
      get '/dashboards/company'
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /dashboards/departments' do
    it 'renders departments dashboard' do
      get '/dashboards/departments'
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /dashboards/trends' do
    it 'renders trends dashboard' do
      get '/dashboards/trends', params: { months: 0 }
      expect(response).to have_http_status(:ok)
    end
  end
end
