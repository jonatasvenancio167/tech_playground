require 'rails_helper'

RSpec.describe 'Api::V1::Imports', type: :request do
  # Set ActiveJob queue adapter to :test for request specs with job assertions
  before do
    ActiveJob::Base.queue_adapter = :test
  end

  # Default headers for API requests
  let(:api_headers) do
    {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json',
      'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }
  end

  let(:multipart_headers) do
    {
      'Accept' => 'application/json',
      'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }
  end

  describe 'POST /api/v1/imports' do
    let(:csv_content) do
      <<~CSV
        email_corporativo;nome;email
        john@company.com;John Doe;john@email.com
      CSV
    end

    let(:temp_file) do
      file = Tempfile.new(['test_import', '.csv'])
      file.write(csv_content)
      file.rewind
      file
    end

    let(:csv_file) do
      Rack::Test::UploadedFile.new(temp_file.path, 'text/csv', true, original_filename: 'test_import.csv')
    end

    after do
      temp_file.close
      temp_file.unlink
    end

    context 'with a valid CSV file' do
      it 'returns accepted status' do
        post '/api/v1/imports', params: { file: csv_file }, headers: multipart_headers
        expect(response).to have_http_status(:accepted)
      end

      it 'creates a CsvImport record' do
        expect {
          post '/api/v1/imports', params: { file: csv_file }, headers: multipart_headers
        }.to change(CsvImport, :count).by(1)
      end

      it 'enqueues a CsvImportJob' do
        expect {
          post '/api/v1/imports', params: { file: csv_file }, headers: multipart_headers
        }.to have_enqueued_job(CsvImportJob)
      end

      it 'returns the import id and status URL' do
        post '/api/v1/imports', params: { file: csv_file }, headers: multipart_headers
        json = JSON.parse(response.body)

        expect(json['id']).to be_present
        expect(json['status']).to eq('pending')
        expect(json['message']).to be_present
        expect(json['status_url']).to be_present
      end
    end

    context 'without a file' do
      it 'returns bad request status' do
        post '/api/v1/imports', headers: multipart_headers
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns an error message' do
        post '/api/v1/imports', headers: multipart_headers
        json = JSON.parse(response.body)
        expect(json['error']).to be_present
      end
    end

    context 'with invalid file parameter' do
      it 'returns bad request for non-file parameter' do
        post '/api/v1/imports', params: { file: 'not_a_file' }, headers: multipart_headers
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'GET /api/v1/imports/:id' do
    context 'with a pending import' do
      let(:csv_import) { create(:csv_import, :pending) }

      it 'returns the import status' do
        get "/api/v1/imports/#{csv_import.id}", headers: api_headers
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['id']).to eq(csv_import.id)
        expect(json['status']).to eq('pending')
      end
    end

    context 'with a processing import' do
      let(:csv_import) { create(:csv_import, :processing) }

      it 'returns progress information' do
        get "/api/v1/imports/#{csv_import.id}", headers: api_headers
        json = JSON.parse(response.body)

        expect(json['status']).to eq('processing')
        expect(json['progress']).to be_present
        expect(json['progress']['total_rows']).to eq(csv_import.total_rows)
        expect(json['progress']['processed_rows']).to eq(csv_import.processed_rows)
        expect(json['progress']['percentage']).to be_present
      end
    end

    context 'with a completed import' do
      let(:csv_import) { create(:csv_import, :completed) }

      it 'returns results information' do
        get "/api/v1/imports/#{csv_import.id}", headers: api_headers
        json = JSON.parse(response.body)

        expect(json['status']).to eq('completed')
        expect(json['results']).to be_present
        expect(json['results']['employees_created']).to eq(csv_import.employees_created)
        expect(json['results']['responses_created']).to eq(csv_import.responses_created)
        expect(json['duration']).to be_present
      end
    end

    context 'with a completed import with errors' do
      let(:csv_import) { create(:csv_import, :completed_with_errors) }

      it 'returns errors in the response' do
        get "/api/v1/imports/#{csv_import.id}", headers: api_headers
        json = JSON.parse(response.body)

        expect(json['results']['errors']).to be_present
        expect(json['results']['errors'].length).to be > 0
      end
    end

    context 'with a failed import' do
      let(:csv_import) { create(:csv_import, :failed) }

      it 'returns error message' do
        get "/api/v1/imports/#{csv_import.id}", headers: api_headers
        json = JSON.parse(response.body)

        expect(json['status']).to eq('failed')
        expect(json['error_message']).to be_present
      end
    end

    context 'with non-existent import' do
      it 'returns not found' do
        get '/api/v1/imports/999999', headers: api_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /api/v1/imports' do
    before do
      create_list(:csv_import, 5, :completed)
      create_list(:csv_import, 3, :failed)
    end

    it 'returns a list of imports' do
      get '/api/v1/imports', headers: api_headers
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json.length).to eq(8)
    end

    it 'returns imports in descending order by created_at' do
      get '/api/v1/imports', headers: api_headers
      json = JSON.parse(response.body)

      created_dates = json.map { |i| i['created_at'] }
      expect(created_dates).to eq(created_dates.sort.reverse)
    end

    it 'includes expected fields for each import' do
      get '/api/v1/imports', headers: api_headers
      json = JSON.parse(response.body)
      import = json.first

      expect(import).to have_key('id')
      expect(import).to have_key('status')
      expect(import).to have_key('status_label')
      expect(import).to have_key('file_name')
      expect(import).to have_key('progress_percentage')
      expect(import).to have_key('employees_created')
      expect(import).to have_key('responses_created')
      expect(import).to have_key('has_errors')
      expect(import).to have_key('created_at')
    end

    it 'limits results to 20' do
      create_list(:csv_import, 20, :completed)
      get '/api/v1/imports', headers: api_headers
      json = JSON.parse(response.body)

      expect(json.length).to eq(20)
    end
  end
end
