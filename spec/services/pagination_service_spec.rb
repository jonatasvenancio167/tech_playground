require 'rails_helper'

RSpec.describe PaginationService, type: :service do
  it 'paginates scope clamping page and per_page bounds' do
    employees = create_list(:employee, 30)
    scope = Employee.order(:id)
    results, meta = described_class.paginate(scope, { page: -1, per_page: 1000 })

    expect(meta[:page]).to eq(1)
    expect(meta[:per_page]).to eq(100)
    expect(meta[:total]).to eq(employees.count)
    expect(results.length).to eq(100).or eq(employees.count) # if less than 100 created
  end
end

