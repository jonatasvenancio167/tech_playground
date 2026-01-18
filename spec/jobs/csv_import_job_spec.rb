require 'rails_helper'

RSpec.describe CsvImportJob, type: :job do
  include ActiveJob::TestHelper

  let(:csv_content) do
    <<~CSV
      email_corporativo;nome;email;celular;area;cargo;funcao;localidade;tempo_de_empresa;genero;geracao;n0_empresa;n1_diretoria;n2_gerencia;n3_coordenacao;n4_area;Data da Resposta;Interesse no Cargo;Comentários - Interesse no Cargo;Contribuição;Comentários - Contribuição;Aprendizado e Desenvolvimento;Comentários - Aprendizado e Desenvolvimento;Feedback;Comentários - Feedback;Interação com Gestor;Comentários - Interação com Gestor;Clareza sobre Possibilidades de Carreira;Comentários - Clareza sobre Possibilidades de Carreira;Expectativa de Permanência;Comentários - Expectativa de Permanência;eNPS;[Aberta] eNPS
      john@company.com;John Doe;john@personal.com;11999999999;Engineering;Developer;Backend;São Paulo;24;Masculino;Millennial;Tech Playground;Technology;Dev Team;Backend;API;2025-01-15;6;Good;7;Excellent;5;;6;;7;;6;;7;;9;Love it here
    CSV
  end

  let(:file_path) { Rails.root.join('tmp', 'test_import.csv').to_s }
  let(:csv_import) { create(:csv_import, :pending, file_path: file_path) }

  before do
    FileUtils.mkdir_p(File.dirname(file_path))
    File.write(file_path, csv_content)
  end

  after do
    FileUtils.rm_f(file_path)
  end

  describe '#perform' do
    it 'processes the CSV file' do
      expect {
        described_class.new.perform(csv_import.id)
      }.to change(Employee, :count).by(1)
        .and change(Response, :count).by(1)
    end

    it 'updates the import status to completed' do
      described_class.new.perform(csv_import.id)
      csv_import.reload

      expect(csv_import.status).to eq('completed')
      expect(csv_import.employees_created).to eq(1)
      expect(csv_import.responses_created).to eq(1)
      expect(csv_import.completed_at).to be_present
    end

    it 'sets started_at when processing begins' do
      described_class.new.perform(csv_import.id)
      csv_import.reload

      expect(csv_import.started_at).to be_present
    end

    it 'cleans up the file after processing' do
      described_class.new.perform(csv_import.id)
      expect(File.exist?(file_path)).to be false
    end

    context 'when import is already processing' do
      let(:csv_import) { create(:csv_import, :processing, file_path: file_path) }

      it 'does not process again' do
        expect {
          described_class.new.perform(csv_import.id)
        }.not_to change(Employee, :count)
      end
    end

    context 'when import is already completed' do
      let(:csv_import) { create(:csv_import, :completed, file_path: file_path) }

      it 'does not process again' do
        expect {
          described_class.new.perform(csv_import.id)
        }.not_to change(Employee, :count)
      end
    end

    context 'when file does not exist' do
      before do
        FileUtils.rm_f(file_path)
      end

      it 'marks the import as failed' do
        expect {
          described_class.new.perform(csv_import.id)
        }.to raise_error(RuntimeError)

        csv_import.reload
        expect(csv_import.status).to eq('failed')
        expect(csv_import.error_message).to be_present
      end
    end

  end

  describe 'job configuration' do
    it 'is queued in the default queue' do
      expect(described_class.new.queue_name).to eq('default')
    end

    it 'enqueues the job' do
      expect {
        described_class.perform_later(csv_import.id)
      }.to have_enqueued_job(described_class).with(csv_import.id)
    end
  end

  describe 'retry configuration' do
    it 'has retry_on configured for ActiveRecord::Deadlocked' do
      # Check that the job class has retry configuration
      handlers = described_class.rescue_handlers
      deadlock_handler = handlers.find { |h| h[0] == 'ActiveRecord::Deadlocked' }
      expect(deadlock_handler).to be_present
    end

    it 'has discard_on configured for ActiveJob::DeserializationError' do
      handlers = described_class.rescue_handlers
      deserialization_handler = handlers.find { |h| h[0] == 'ActiveJob::DeserializationError' }
      expect(deserialization_handler).to be_present
    end
  end
end
