class ResponseSerializer
  def self.render(collection)
    collection.map do |r|
      {
        id: r.id,
        employee_id: r.employee_id,
        response_date: r.response_date,
        interest_in_position: r.interest_in_position,
        contribution: r.contribution,
        learning_and_development: r.learning_and_development,
        feedback: r.feedback,
        interaction_with_manager: r.interaction_with_manager,
        career_opportunity_clarity: r.career_opportunity_clarity,
        permanence_expectation: r.permanence_expectation,
        enps: r.enps
      }
    end
  end
end

