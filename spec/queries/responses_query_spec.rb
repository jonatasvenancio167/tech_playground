require 'rails_helper'

RSpec.describe ResponsesQuery, type: :model do
  let(:employee) { create(:employee, department: 'engineering') }
  let!(:older) { create(:response, employee: employee, response_date: 10.days.ago) }
  let!(:newer) { create(:response, employee: employee, response_date: 2.days.ago) }

  it 'orders by response_date desc and filters by employee_id' do
    scope = described_class.new(employee_id: employee.id).call
    expect(scope.first).to eq(newer)
    expect(scope.last).to eq(older)
  end

  it 'filters by date range and department' do
    scope = described_class.new(
      date_from: 5.days.ago.to_date.to_s,
      date_to: Date.current.to_s,
      department: 'engineering'
    ).call
    expect(scope).to include(newer)
    expect(scope).not_to include(older)
  end
end

