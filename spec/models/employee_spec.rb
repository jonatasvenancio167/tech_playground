require 'rails_helper'

RSpec.describe Employee, type: :model do
  describe 'associations' do
    it { should have_many(:responses).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:employee) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should allow_value('test@example.com').for(:email) }
    it { should_not allow_value('invalid-email').for(:email) }
    it { should allow_value('').for(:corporate_email) }
    it { should allow_value('corp@company.com').for(:corporate_email) }
    it { should_not allow_value('invalid-corp-email').for(:corporate_email) }
  end

  describe 'scopes' do
    let!(:engineering_employee) { create(:employee, :engineering) }
    let!(:sales_employee) { create(:employee, :sales) }
    let!(:sp_employee) { create(:employee, location: 'São Paulo') }
    let!(:rj_employee) { create(:employee, location: 'Rio de Janeiro') }
    let!(:millennial) { create(:employee, generation: 'Millennial') }
    let!(:gen_z) { create(:employee, generation: 'Geração Z') }

    describe '.by_department' do
      it 'filters employees by department' do
        expect(Employee.by_department('engineering')).to include(engineering_employee)
        expect(Employee.by_department('engineering')).not_to include(sales_employee)
      end
    end

    describe '.by_location' do
      it 'filters employees by location' do
        expect(Employee.by_location('São Paulo')).to include(sp_employee)
        expect(Employee.by_location('São Paulo')).not_to include(rj_employee)
      end
    end

    describe '.by_generation' do
      it 'filters employees by generation' do
        expect(Employee.by_generation('Millennial')).to include(millennial)
        expect(Employee.by_generation('Millennial')).not_to include(gen_z)
      end
    end

    describe '.with_responses' do
      let!(:employee_with_response) { create(:employee, :with_responses) }
      let!(:employee_without_response) { create(:employee) }

      it 'returns only employees with responses' do
        expect(Employee.with_responses).to include(employee_with_response)
        expect(Employee.with_responses).not_to include(employee_without_response)
      end
    end

    describe '.without_responses' do
      let!(:employee_with_response) { create(:employee, :with_responses) }
      let!(:employee_without_response) { create(:employee) }

      it 'returns only employees without responses' do
        expect(Employee.without_responses).to include(employee_without_response)
        expect(Employee.without_responses).not_to include(employee_with_response)
      end
    end
  end

  describe 'callbacks' do
    describe '#normalize_department' do
      it 'normalizes department to lowercase and stripped' do
        employee = create(:employee, department: '  ENGINEERING  ')
        expect(employee.department).to eq('engineering')
      end

      it 'handles nil department' do
        employee = create(:employee, department: nil)
        expect(employee.department).to be_nil
      end
    end
  end

  describe 'instance methods' do
    describe '#response_rate' do
      context 'when employee has no responses' do
        let(:employee) { create(:employee) }

        it 'returns 0' do
          expect(employee.response_rate).to eq(0)
        end
      end

      context 'when employee has responses' do
        let(:employee) { create(:employee, :with_responses) }

        it 'returns 100' do
          expect(employee.response_rate).to eq(100.0)
        end
      end
    end

    describe '#average_score' do
      let(:employee) { create(:employee) }

      before do
        create(:response, employee: employee, interest_in_position: 5)
        create(:response, employee: employee, interest_in_position: 7, response_date: 1.day.ago)
      end

      it 'calculates average score for a given field' do
        expect(employee.average_score(:interest_in_position)).to eq(6.0)
      end
    end

    describe '#latest_response' do
      let(:employee) { create(:employee) }
      let!(:old_response) { create(:response, employee: employee, response_date: 1.month.ago) }
      let!(:recent_response) { create(:response, employee: employee, response_date: Date.current) }

      it 'returns the most recent response' do
        expect(employee.latest_response).to eq(recent_response)
      end
    end

    describe '#enps_category' do
      context 'when employee is a promoter' do
        let(:employee) { create(:employee) }

        before do
          create(:response, :promoter, employee: employee)
        end

        it 'returns promoter' do
          expect(employee.enps_category).to eq('promoter')
        end
      end

      context 'when employee is a detractor' do
        let(:employee) { create(:employee) }

        before do
          create(:response, :detractor, employee: employee)
        end

        it 'returns detractor' do
          expect(employee.enps_category).to eq('detractor')
        end
      end

      context 'when employee has no responses' do
        let(:employee) { create(:employee) }

        it 'returns nil' do
          expect(employee.enps_category).to be_nil
        end
      end
    end

    describe '#average_enps' do
      let(:employee) { create(:employee) }

      before do
        create(:response, employee: employee, enps: 8)
        create(:response, employee: employee, enps: 10, response_date: 1.day.ago)
      end

      it 'calculates average eNPS score' do
        expect(employee.average_enps).to eq(9.0)
      end
    end
  end
end
