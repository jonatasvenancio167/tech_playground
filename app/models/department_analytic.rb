class DepartmentAnalytic < ApplicationRecord
  self.table_name = "department_analytics"
  self.primary_key = :department

  def readonly?
    true
  end

  def self.refresh!
    connection.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY department_analytics")
  end

  scope :by_enps, -> { order(enps_score: :desc) }
  scope :best_performers, -> { where("enps_score > ?", 50) }
  scope :needs_attention, -> { where("enps_score < ?", 0) }

  def self.low_favorability(threshold = 60)
    where("favorability_interest < :threshold OR
           favorability_contribution < :threshold OR
           favorability_learning < :threshold OR
           favorability_feedback < :threshold OR
           favorability_manager < :threshold OR
           favorability_career < :threshold OR
           favorability_permanence < :threshold", threshold: threshold)
  end

  def top_dimensions(n = 3)
    dimensions = {
      interest_in_position: favorability_interest,
      contribution: favorability_contribution,
      learning_and_development: favorability_learning,
      feedback: favorability_feedback,
      interaction_with_manager: favorability_manager,
      career_opportunity_clarity: favorability_career,
      permanence_expectation: favorability_permanence
    }
    dimensions.sort_by { |_, v| -v.to_f }.first(n).to_h
  end

  def areas_for_improvement(threshold = 60)
    dimensions = {
      interest_in_position: favorability_interest,
      contribution: favorability_contribution,
      learning_and_development: favorability_learning,
      feedback: favorability_feedback,
      interaction_with_manager: favorability_manager,
      career_opportunity_clarity: favorability_career,
      permanence_expectation: favorability_permanence
    }
    dimensions.select { |_, v| v.to_f < threshold }
  end
end
