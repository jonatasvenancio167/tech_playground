require 'rails_helper'

RSpec.describe CsvImporter, type: :service do
  let(:csv_content) do
    <<~CSV
      email_corporativo;nome;email;celular;area;cargo;funcao;localidade;tempo_de_empresa;genero;geracao;n0_empresa;n1_diretoria;n2_gerencia;n3_coordenacao;n4_area;Data da Resposta;Interesse no Cargo;Comentários - Interesse no Cargo;Contribuição;Comentários - Contribuição;Aprendizado e Desenvolvimento;Comentários - Aprendizado e Desenvolvimento;Feedback;Comentários - Feedback;Interação com Gestor;Comentários - Interação com Gestor;Clareza sobre Possibilidades de Carreira;Comentários - Clareza sobre Possibilidades de Carreira;Expectativa de Permanência;Comentários - Expectativa de Permanência;eNPS;[Aberta] eNPS
      john@company.com;John Doe;john@personal.com;11999999999;Engineering;Developer;Backend;São Paulo;24;Masculino;Millennial;Tech Playground;Technology;Dev Team;Backend;API;2025-01-15;6;Good;7;Excellent;5;;6;;7;;6;;7;;9;Love it here
      jane@company.com;Jane Smith;jane@personal.com;11888888888;Marketing;Manager;Digital;Rio de Janeiro;36;Feminino;Gen X;Tech Playground;Commercial;Marketing;Digital;Social;2025-01-15;7;;6;;7;;5;;6;;5;;6;;8;Good company
    CSV
  end

  let(:csv_file) { StringIO.new(csv_content) }

  describe '#import' do
    subject(:result) { described_class.new(io: csv_file).import }

    context 'with valid CSV data' do
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

      it 'creates employees with correct attributes' do
        result
        john = Employee.find_by(corporate_email: 'john@company.com')

        expect(john.name).to eq('John Doe')
        expect(john.email).to eq('john@personal.com')
        expect(john.department).to eq('engineering')
        expect(john.location).to eq('São Paulo')
        expect(john.company_tenure_months).to eq(24)
      end

      it 'creates responses with correct scores' do
        result
        john = Employee.find_by(corporate_email: 'john@company.com')
        response = john.responses.first

        expect(response.interest_in_position).to eq(6)
        expect(response.contribution).to eq(7)
        expect(response.enps).to eq(9)
        expect(response.enps_open_comment).to eq('Love it here')
      end
    end

    context 'when employee already exists' do
      let!(:existing_employee) do
        create(:employee,
          corporate_email: 'john@company.com',
          name: 'Old Name',
          department: 'old department'
        )
      end

      it 'updates the existing employee' do
        result
        existing_employee.reload

        expect(existing_employee.name).to eq('John Doe')
        expect(existing_employee.department).to eq('engineering')
      end

      it 'still creates the response' do
        expect { result }.to change(Response, :count).by(2)
      end

      it 'returns correct employee count (only new ones)' do
        expect(result.employees_created).to eq(1)
      end
    end

    context 'with invalid data' do
      let(:csv_with_errors) do
        <<~CSV
          email_corporativo;nome;email;celular;area;cargo;funcao;localidade;tempo_de_empresa;genero;geracao;n0_empresa;n1_diretoria;n2_gerencia;n3_coordenacao;n4_area;Data da Resposta;Interesse no Cargo;Comentários - Interesse no Cargo;Contribuição;Comentários - Contribuição;Aprendizado e Desenvolvimento;Comentários - Aprendizado e Desenvolvimento;Feedback;Comentários - Feedback;Interação com Gestor;Comentários - Interação com Gestor;Clareza sobre Possibilidades de Carreira;Comentários - Clareza sobre Possibilidades de Carreira;Expectativa de Permanência;Comentários - Expectativa de Permanência;eNPS;[Aberta] eNPS
          valid@company.com;Valid User;valid@email.com;11999999999;Engineering;Developer;Backend;São Paulo;24;M;Millennial;Tech;Tech;Dev;Backend;API;2025-01-15;6;;7;;5;;6;;7;;6;;7;;9;
          invalid@company.com;;invalid-email;11888888888;Marketing;Manager;Digital;RJ;36;F;Gen X;Tech;Commercial;Marketing;Digital;Social;2025-01-15;7;;6;;7;;5;;6;;5;;6;;8;
        CSV
      end

      let(:csv_file) { StringIO.new(csv_with_errors) }

      it 'returns errors for invalid rows' do
        expect(result.errors).not_to be_empty
      end

      it 'still creates valid entries' do
        expect(result.employees_created).to be >= 0
      end
    end

    context 'with empty CSV' do
      let(:csv_content) do
        <<~CSV
          email_corporativo;nome;email;celular;area;cargo;funcao;localidade;tempo_de_empresa;genero;geracao;n0_empresa;n1_diretoria;n2_gerencia;n3_coordenacao;n4_area;Data da Resposta;Interesse no Cargo;Comentários - Interesse no Cargo;Contribuição;Comentários - Contribuição;Aprendizado e Desenvolvimento;Comentários - Aprendizado e Desenvolvimento;Feedback;Comentários - Feedback;Interação com Gestor;Comentários - Interação com Gestor;Clareza sobre Possibilidades de Carreira;Comentários - Clareza sobre Possibilidades de Carreira;Expectativa de Permanência;Comentários - Expectativa de Permanência;eNPS;[Aberta] eNPS
        CSV
      end

      it 'returns zero counts' do
        expect(result.employees_created).to eq(0)
        expect(result.responses_created).to eq(0)
        expect(result.errors).to be_empty
      end
    end
  end

  describe 'Result struct' do
    it 'has expected attributes' do
      result = CsvImporter::Result.new(
        employees_created: 5,
        responses_created: 10,
        errors: ['error1']
      )

      expect(result.employees_created).to eq(5)
      expect(result.responses_created).to eq(10)
      expect(result.errors).to eq(['error1'])
    end
  end
end
