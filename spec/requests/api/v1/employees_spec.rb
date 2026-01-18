require 'rails_helper'

RSpec.describe 'Api::V1::Employees', type: :request do
  let(:headers) { { 'Accept' => 'application/json' } }

  before do
    @eng = create(:employee, :engineering, name: 'Alice', email: 'alice@example.com')
    @mkt = create(:employee, :sales, name: 'Bob', email: 'bob@example.com', location: 'Rio de Janeiro')
  end

  describe 'GET /api/v1/employees' do
    it 'lists employees with pagination and filters' do
      get '/api/v1/employees', headers: headers, params: { department: 'engineering', page: 1, per_page: 25 }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']).to be_an(Array)
      names = json['data'].map { |e| e['name'] }
      expect(names).to include('Alice')
      expect(names).not_to include('Bob') # filtered by department
      expect(json['meta']).to include('page', 'per_page', 'total')
    end

    it 'supports full-text search by name/email' do
      get '/api/v1/employees', headers: headers, params: { q: 'alice' }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      names = json['data'].map { |e| e['name'] }
      expect(names).to include('Alice')
    end
  end

  describe 'GET /api/v1/employees/:id' do
    it 'shows an employee details' do
      get "/api/v1/employees/#{@eng.id}", headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(@eng.id)
      expect(json['name']).to eq('Alice')
      expect(json['email']).to eq('alice@example.com')
    end
  end
end

