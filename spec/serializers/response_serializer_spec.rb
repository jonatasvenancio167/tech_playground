require 'rails_helper'

RSpec.describe ResponseSerializer do
  it 'serializes a collection of responses' do
    e = create(:employee)
    r1 = create(:response, employee: e, interest_in_position: 6, enps: 9)
    r2 = create(:response, employee: e, interest_in_position: 3, enps: 5)

    json = described_class.render([r1, r2])

    expect(json.length).to eq(2)
    expect(json.first[:id]).to eq(r1.id)
    expect(json.first[:employee_id]).to eq(e.id)
    expect(json.first[:enps]).to eq(9)
    expect(json.last[:interest_in_position]).to eq(3)
  end
end

