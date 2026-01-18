class CompanyAnalytic < ApplicationRecord
  self.table_name = "company_analytics"

  def readonly?
    true
  end

  def self.refresh!
    connection.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY company_analytics")
  end

  def self.current
    first
  end

  def engagement_level
    case response_rate.to_f
    when 0..30 then "low"
    when 30..60 then "medium"
    when 60..80 then "good"
    else "excellent"
    end
  end

  def enps_level
    case enps_score.to_f
    when -100..-1 then "critical"
    when 0..30 then "needs_improvement"
    when 30..50 then "good"
    when 50..70 then "very_good"
    else "excellent"
    end
  end

  def favorability_ranking
    {
      interest_in_position: favorability_interest,
      contribution: favorability_contribution,
      learning_and_development: favorability_learning,
      feedback: favorability_feedback,
      interaction_with_manager: favorability_manager,
      career_opportunity_clarity: favorability_career,
      permanence_expectation: favorability_permanence
    }.sort_by { |_, v| -v.to_f }.to_h
  end

  def top_strengths
    favorability_ranking.first(3)
  end

  def improvement_areas
    favorability_ranking.last(3).reverse.to_h
  end
end
