class Response < ApplicationRecord
  belongs_to :employee

  # Campos com escala Likert 1-7 conforme dados do CSV
  LIKERT_FIELDS = %i[
    interest_in_position
    contribution
    learning_and_development
    feedback
    interaction_with_manager
    career_opportunity_clarity
    permanence_expectation
  ].freeze

  # Threshold para favorabilidade (scores >= 6 são favoráveis na escala 1-7)
  FAVORABLE_THRESHOLD = 6

  validates :interest_in_position, :contribution, :learning_and_development,
            :feedback, :interaction_with_manager, :career_opportunity_clarity,
            :permanence_expectation,
            inclusion: { in: 1..7 }, allow_nil: true

  validates :enps, inclusion: { in: 0..10 }, allow_nil: true

  validates :response_date, presence: true

  validates :response_date, uniqueness: { scope: :employee_id }

  # Scopes
  scope :recent, -> { order(response_date: :desc) }
  scope :by_date_range, ->(start_date, end_date) { 
    where(response_date: start_date..end_date) 
  }
  scope :this_year, -> { where('response_date >= ?', Date.current.beginning_of_year) }
  scope :last_month, -> { where('response_date >= ?', 1.month.ago) }
  scope :promoters, -> { where(enps: 9..10) }
  scope :passives, -> { where(enps: 7..8) }
  scope :detractors, -> { where(enps: 0..6) }

  def enps_category
    return nil unless enps
    case enps
    when 9..10 then 'promoter'
    when 7..8  then 'passive'
    when 0..6  then 'detractor'
    end
  end

  def promoter?
    enps_category == 'promoter'
  end
  
  def passive?
    enps_category == 'passive'
  end
  
  def detractor?
    enps_category == 'detractor'
  end
  
  # Cálculo de Favorabilidade
  # Escala 1-7: favorável >= 6, neutro = 4-5, desfavorável <= 3
  def favorable_responses_count
    likert_scores.count { |score| score >= FAVORABLE_THRESHOLD }
  end

  def unfavorable_responses_count
    likert_scores.count { |score| score <= 3 }
  end

  def neutral_responses_count
    likert_scores.count { |score| score.between?(4, 5) }
  end
  
  def total_responses_count
    likert_scores.compact.size
  end
  
  def favorability_percentage
    return 0 if total_responses_count.zero?
    (favorable_responses_count.to_f / total_responses_count * 100).round(2)
  end
  
  def average_likert_score
    return 0 if likert_scores.empty?
    (likert_scores.sum.to_f / likert_scores.size).round(2)
  end
  
  def at_risk?
    average_likert_score < 5 || detractor?
  end
  
  def all_comments
    {
      interest_in_position: interest_in_position_comment,
      contribution: contribution_comment,
      learning_and_development: learning_and_development_comment,
      feedback: feedback_comment,
      interaction_with_manager: interaction_with_manager_comment,
      career_opportunity_clarity: career_opportunity_clarity_comment,
      permanence_expectation: permanence_expectation_comment,
      enps: enps_open_comment
    }.compact
  end
  
  def has_comments?
    all_comments.values.any?(&:present?)
  end
  
  def as_summary
    {
      id: id,
      date: response_date,
      scores: {
        interest_in_position: interest_in_position,
        contribution: contribution,
        learning_and_development: learning_and_development,
        feedback: feedback,
        interaction_with_manager: interaction_with_manager,
        career_opportunity_clarity: career_opportunity_clarity,
        permanence_expectation: permanence_expectation
      },
      enps: enps,
      enps_category: enps_category,
      favorability: favorability_percentage,
      average: average_likert_score,
      at_risk: at_risk?
    }
  end

  def self.refresh_analytics!
    ActiveRecord::Base.connection.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY department_analytics")
    ActiveRecord::Base.connection.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY location_analytics")
    ActiveRecord::Base.connection.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY company_analytics")
  end

  private

  def likert_scores
    LIKERT_FIELDS.map { |field| send(field) }.compact
  end
end

