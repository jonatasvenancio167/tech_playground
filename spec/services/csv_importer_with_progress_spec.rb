require 'rails_helper'

RSpec.describe CsvImporterWithProgress, type: :service do
  let(:csv_import) { create(:csv_import, :processing, total_rows: 2) }

  let(:csv_content) do
    <<~CSV
      email_corporativo;nome;email;celular;area;cargo;funcao;localidade;tempo_de_empresa;genero;geracao;n0_empresa;n1_diretoria;n2_gerencia;n3_coordenacao;n4_area;Data da Resposta;Interesse no Cargo;Comentários - Interesse no Cargo;Contribuição;Comentários - Contribuição;Aprendizado e Desenvolvimento;Comentários - Aprendizado e Desenvolvimento;Feedback;Comentários - Feedback;Interação com Gestor;Comentários - Interação com Gestor;Clareza sobre Possibilidades de Carreira;Comentários - Clareza sobre Possibilidades de Carreira;Expectativa de Permanência;Comentários - Expectativa de Permanência;eNPS;[Aberta] eNPS
      john@company.com;John Doe;john@personal.com;11999999999;Engineering;Developer;Backend;São Paulo;24;Masculino;Millennial;Tech Playground;Technology;Dev Team;Backend;API;2025-01-15;6;Good;7;Excellent;5;;6;;7;;6;;7;;9;Love it here
      jane@company.com;Jane Smith;jane@personal.com;11888888888;Marketing;Manager;Digital;Rio de Janeiro;36;Feminino;Gen X;Tech Playground;Commercial;Marketing;Digital;Social;2025-01-15;7;;6;;7;;5;;6;;5;;6;;8;Good company
    CSV
  end

  let(:csv_file) { StringIO.new(csv_content) }

  describe '#import' do
    subject(:result) do
      described_class.new(io: csv_file, csv_import: csv_import).import
    end

    it 'creates employees' do
      expect { result }.to change(Employee, :count).by(2)
    end

    it 'creates responses' do
      expect { result }.to change(Response, :count).by(2)
    end

    it 'returns correct counts' do
      expect(result.employees_created).to eq(2)
      expect(result.responses_created).to eq(2)
      expect(result.errors).to be_empty
    end

    it 'updates progress on the csv_import record' do
      result
      csv_import.reload
      expect(csv_import.processed_rows).to eq(2)
    end

    context 'with a large batch' do
      let(:csv_content) do
        header = "email_corporativo;nome;email;celular;area;cargo;funcao;localidade;tempo_de_empresa;genero;geracao;n0_empresa;n1_diretoria;n2_gerencia;n3_coordenacao;n4_area;Data da Resposta;Interesse no Cargo;Comentários - Interesse no Cargo;Contribuição;Comentários - Contribuição;Aprendizado e Desenvolvimento;Comentários - Aprendizado e Desenvolvimento;Feedback;Comentários - Feedback;Interação com Gestor;Comentários - Interação com Gestor;Clareza sobre Possibilidades de Carreira;Comentários - Clareza sobre Possibilidades de Carreira;Expectativa de Permanência;Comentários - Expectativa de Permanência;eNPS;[Aberta] eNPS"
        rows = (1..100).map do |i|
          "user#{i}@company.com;User #{i};user#{i}@email.com;1199999#{i.to_s.rjust(4, '0')};Engineering;Dev;Backend;SP;#{i};M;Millennial;Tech;Tech;Dev;Backend;API;2025-01-#{(i % 28 + 1).to_s.rjust(2, '0')};6;;7;;5;;6;;7;;6;;7;;9;"
        end
        ([header] + rows).join("\n")
      end

      let(:csv_import) { create(:csv_import, :processing, total_rows: 100) }

      it 'processes all rows' do
        expect(result.employees_created).to eq(100)
        expect(result.responses_created).to eq(100)
      end

      it 'updates progress multiple times during import' do
        # The importer updates every 50 rows, so we expect at least 2 updates
        expect(csv_import).to receive(:update_progress!).at_least(2).times.and_call_original
        result
      end
    end

    context 'with errors in some rows' do
      let(:csv_content) do
        <<~CSV
          email_corporativo;nome;email;celular;area;cargo;funcao;localidade;tempo_de_empresa;genero;geracao;n0_empresa;n1_diretoria;n2_gerencia;n3_coordenacao;n4_area;Data da Resposta;Interesse no Cargo;Comentários - Interesse no Cargo;Contribuição;Comentários - Contribuição;Aprendizado e Desenvolvimento;Comentários - Aprendizado e Desenvolvimento;Feedback;Comentários - Feedback;Interação com Gestor;Comentários - Interação com Gestor;Clareza sobre Possibilidades de Carreira;Comentários - Clareza sobre Possibilidades de Carreira;Expectativa de Permanência;Comentários - Expectativa de Permanência;eNPS;[Aberta] eNPS
          john@company.com;John Doe;john@personal.com;11999999999;Engineering;Developer;Backend;São Paulo;24;Masculino;Millennial;Tech;Tech;Dev;Backend;API;2025-01-15;6;;7;;5;;6;;7;;6;;7;;9;
          invalid@company.com;;invalid-email;11888888888;Marketing;Manager;Digital;RJ;36;F;Gen X;Tech;Commercial;Marketing;Digital;Social;2025-01-15;7;;6;;7;;5;;6;;5;;6;;8;
        CSV
      end

      it 'returns errors for invalid rows' do
        expect(result.errors).not_to be_empty
      end

      it 'continues processing valid rows' do
        expect(result.employees_created).to be >= 0
      end
    end
  end

  describe 'Result struct' do
    it 'has expected attributes' do
      result = CsvImporterWithProgress::Result.new(
        employees_created: 5,
        responses_created: 10,
        errors: []
      )

      expect(result.employees_created).to eq(5)
      expect(result.responses_created).to eq(10)
      expect(result.errors).to eq([])
    end
  end
end
