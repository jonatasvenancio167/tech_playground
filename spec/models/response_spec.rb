require 'rails_helper'

RSpec.describe Response, type: :model do
  describe 'associations' do
    it { should belong_to(:employee) }
  end

  describe 'validations' do
    subject { build(:response) }

    it { should validate_presence_of(:response_date) }

    it { should validate_inclusion_of(:interest_in_position).in_range(1..7).allow_nil }
    it { should validate_inclusion_of(:contribution).in_range(1..7).allow_nil }
    it { should validate_inclusion_of(:learning_and_development).in_range(1..7).allow_nil }
    it { should validate_inclusion_of(:feedback).in_range(1..7).allow_nil }
    it { should validate_inclusion_of(:interaction_with_manager).in_range(1..7).allow_nil }
    it { should validate_inclusion_of(:career_opportunity_clarity).in_range(1..7).allow_nil }
    it { should validate_inclusion_of(:permanence_expectation).in_range(1..7).allow_nil }
    it { should validate_inclusion_of(:enps).in_range(0..10).allow_nil }

    describe 'uniqueness of response_date per employee' do
      let(:employee) { create(:employee) }
      let!(:existing_response) { create(:response, employee: employee, response_date: Date.current) }

      it 'does not allow duplicate response_date for the same employee' do
        duplicate = build(:response, employee: employee, response_date: Date.current)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:response_date]).to be_present
      end

      it 'allows same date for different employees' do
        other_employee = create(:employee)
        response = build(:response, employee: other_employee, response_date: Date.current)
        expect(response).to be_valid
      end
    end
  end

  describe 'scopes' do
    describe '.recent' do
      let(:employee) { create(:employee) }
      let!(:old_response) { create(:response, employee: employee, response_date: 1.year.ago) }
      let!(:new_response) { create(:response, employee: employee, response_date: Date.current) }

      it 'orders by response_date descending' do
        # Filter to only the responses we created to avoid interference from seed data
        responses = Response.recent.where(employee: employee)
        expect(responses.first).to eq(new_response)
        expect(responses.last).to eq(old_response)
      end
    end

    describe '.by_date_range' do
      let!(:in_range) { create(:response, response_date: 15.days.ago) }
      let!(:out_of_range) { create(:response, response_date: 2.months.ago) }

      it 'filters responses within date range' do
        results = Response.by_date_range(1.month.ago, Date.current)
        expect(results).to include(in_range)
        expect(results).not_to include(out_of_range)
      end
    end

    describe '.promoters' do
      let!(:promoter) { create(:response, :promoter) }
      let!(:detractor) { create(:response, :detractor) }

      it 'returns only promoters (eNPS 9-10)' do
        expect(Response.promoters).to include(promoter)
        expect(Response.promoters).not_to include(detractor)
      end
    end

    describe '.passives' do
      let!(:passive) { create(:response, :passive) }
      let!(:promoter) { create(:response, :promoter) }

      it 'returns only passives (eNPS 7-8)' do
        expect(Response.passives).to include(passive)
        expect(Response.passives).not_to include(promoter)
      end
    end

    describe '.detractors' do
      let!(:detractor) { create(:response, :detractor) }
      let!(:promoter) { create(:response, :promoter) }

      it 'returns only detractors (eNPS 0-6)' do
        expect(Response.detractors).to include(detractor)
        expect(Response.detractors).not_to include(promoter)
      end
    end
  end

  describe 'instance methods' do
    describe '#enps_category' do
      it 'returns promoter for eNPS 9-10' do
        response = build(:response, enps: 9)
        expect(response.enps_category).to eq('promoter')

        response.enps = 10
        expect(response.enps_category).to eq('promoter')
      end

      it 'returns passive for eNPS 7-8' do
        response = build(:response, enps: 7)
        expect(response.enps_category).to eq('passive')

        response.enps = 8
        expect(response.enps_category).to eq('passive')
      end

      it 'returns detractor for eNPS 0-6' do
        response = build(:response, enps: 0)
        expect(response.enps_category).to eq('detractor')

        response.enps = 6
        expect(response.enps_category).to eq('detractor')
      end

      it 'returns nil when eNPS is nil' do
        response = build(:response, enps: nil)
        expect(response.enps_category).to be_nil
      end
    end

    describe '#promoter?, #passive?, #detractor?' do
      it 'correctly identifies promoters' do
        response = build(:response, :promoter)
        expect(response.promoter?).to be true
        expect(response.passive?).to be false
        expect(response.detractor?).to be false
      end

      it 'correctly identifies passives' do
        response = build(:response, :passive)
        expect(response.promoter?).to be false
        expect(response.passive?).to be true
        expect(response.detractor?).to be false
      end

      it 'correctly identifies detractors' do
        response = build(:response, :detractor)
        expect(response.promoter?).to be false
        expect(response.passive?).to be false
        expect(response.detractor?).to be true
      end
    end

    describe '#favorable_responses_count' do
      it 'counts responses with score >= 6' do
        response = build(:response,
          interest_in_position: 6,
          contribution: 7,
          learning_and_development: 5,
          feedback: 6,
          interaction_with_manager: 4,
          career_opportunity_clarity: 7,
          permanence_expectation: 3
        )
        expect(response.favorable_responses_count).to eq(4)
      end
    end

    describe '#unfavorable_responses_count' do
      it 'counts responses with score <= 3' do
        response = build(:response,
          interest_in_position: 1,
          contribution: 2,
          learning_and_development: 3,
          feedback: 4,
          interaction_with_manager: 5,
          career_opportunity_clarity: 6,
          permanence_expectation: 7
        )
        expect(response.unfavorable_responses_count).to eq(3)
      end
    end

    describe '#neutral_responses_count' do
      it 'counts responses with score between 4 and 5' do
        response = build(:response,
          interest_in_position: 4,
          contribution: 5,
          learning_and_development: 4,
          feedback: 5,
          interaction_with_manager: 6,
          career_opportunity_clarity: 3,
          permanence_expectation: 7
        )
        expect(response.neutral_responses_count).to eq(4)
      end
    end

    describe '#favorability_percentage' do
      it 'calculates the percentage of favorable responses' do
        response = build(:response, :highly_favorable)
        expect(response.favorability_percentage).to eq(100.0)
      end

      it 'returns 0 when no responses' do
        response = build(:response,
          interest_in_position: nil,
          contribution: nil,
          learning_and_development: nil,
          feedback: nil,
          interaction_with_manager: nil,
          career_opportunity_clarity: nil,
          permanence_expectation: nil
        )
        expect(response.favorability_percentage).to eq(0)
      end
    end

    describe '#average_likert_score' do
      it 'calculates average of all Likert scores' do
        response = build(:response,
          interest_in_position: 5,
          contribution: 6,
          learning_and_development: 7,
          feedback: 4,
          interaction_with_manager: 5,
          career_opportunity_clarity: 6,
          permanence_expectation: 7
        )
        # Average: (5+6+7+4+5+6+7) / 7 = 40/7 ≈ 5.71
        expect(response.average_likert_score).to eq(5.71)
      end
    end

    describe '#at_risk?' do
      it 'returns true when average is below 5' do
        response = build(:response, :unfavorable)
        expect(response.at_risk?).to be true
      end

      it 'returns true when employee is a detractor' do
        response = build(:response, :highly_favorable, enps: 5)
        expect(response.at_risk?).to be true
      end

      it 'returns false when average >= 5 and not detractor' do
        response = build(:response, :highly_favorable, enps: 9)
        expect(response.at_risk?).to be false
      end
    end

    describe '#all_comments' do
      it 'returns hash with all non-nil comments' do
        response = build(:response,
          interest_in_position_comment: 'Great position',
          contribution_comment: nil,
          enps_open_comment: 'Love this company'
        )
        comments = response.all_comments
        expect(comments[:interest_in_position]).to eq('Great position')
        expect(comments[:enps]).to eq('Love this company')
        expect(comments).not_to have_key(:contribution)
      end
    end

    describe '#has_comments?' do
      it 'returns true when has at least one comment' do
        response = build(:response, :with_all_comments)
        expect(response.has_comments?).to be true
      end

      it 'returns false when no comments' do
        response = build(:response,
          interest_in_position_comment: nil,
          contribution_comment: nil,
          learning_and_development_comment: nil,
          feedback_comment: nil,
          interaction_with_manager_comment: nil,
          career_opportunity_clarity_comment: nil,
          permanence_expectation_comment: nil,
          enps_open_comment: nil
        )
        expect(response.has_comments?).to be false
      end
    end

    describe '#as_summary' do
      let(:response) { create(:response, :promoter) }

      it 'returns a summary hash with all relevant data' do
        summary = response.as_summary

        expect(summary).to have_key(:id)
        expect(summary).to have_key(:date)
        expect(summary).to have_key(:scores)
        expect(summary).to have_key(:enps)
        expect(summary).to have_key(:enps_category)
        expect(summary).to have_key(:favorability)
        expect(summary).to have_key(:average)
        expect(summary).to have_key(:at_risk)

        expect(summary[:enps_category]).to eq('promoter')
        expect(summary[:at_risk]).to be false
      end
    end
  end
end
