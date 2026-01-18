class AddDatabaseOptimizations < ActiveRecord::Migration[8.1]
  def up
    # Dados do CSV usam escala 1-7 para Likert
    # Adicionar constraints de validação para Likert Scale (1-7 ou NULL)
    add_check_constraint :responses, "interest_in_position IS NULL OR (interest_in_position >= 1 AND interest_in_position <= 7)", name: "interest_in_position_range"
    add_check_constraint :responses, "contribution IS NULL OR (contribution >= 1 AND contribution <= 7)", name: "contribution_range"
    add_check_constraint :responses, "learning_and_development IS NULL OR (learning_and_development >= 1 AND learning_and_development <= 7)", name: "learning_and_development_range"
    add_check_constraint :responses, "feedback IS NULL OR (feedback >= 1 AND feedback <= 7)", name: "feedback_range"
    add_check_constraint :responses, "interaction_with_manager IS NULL OR (interaction_with_manager >= 1 AND interaction_with_manager <= 7)", name: "interaction_with_manager_range"
    add_check_constraint :responses, "career_opportunity_clarity IS NULL OR (career_opportunity_clarity >= 1 AND career_opportunity_clarity <= 7)", name: "career_opportunity_clarity_range"
    add_check_constraint :responses, "permanence_expectation IS NULL OR (permanence_expectation >= 1 AND permanence_expectation <= 7)", name: "permanence_expectation_range"

    # Constraint para eNPS (0-10)
    add_check_constraint :responses, "enps IS NULL OR (enps >= 0 AND enps <= 10)", name: "enps_range"

    # Índices compostos para queries analíticas
    add_index :responses, [:employee_id, :enps], name: "index_responses_on_employee_enps"
    add_index :responses, [:response_date, :enps], name: "index_responses_on_date_enps"

    # Índice para cálculo rápido de favorabilidade
    add_index :responses, [:interest_in_position], name: "index_responses_on_interest"
    add_index :responses, [:contribution], name: "index_responses_on_contribution"
    add_index :responses, [:learning_and_development], name: "index_responses_on_learning"
  end

  def down
    remove_check_constraint :responses, name: "interest_in_position_range"
    remove_check_constraint :responses, name: "contribution_range"
    remove_check_constraint :responses, name: "learning_and_development_range"
    remove_check_constraint :responses, name: "feedback_range"
    remove_check_constraint :responses, name: "interaction_with_manager_range"
    remove_check_constraint :responses, name: "career_opportunity_clarity_range"
    remove_check_constraint :responses, name: "permanence_expectation_range"
    remove_check_constraint :responses, name: "enps_range"

    remove_index :responses, name: "index_responses_on_employee_enps"
    remove_index :responses, name: "index_responses_on_date_enps"
    remove_index :responses, name: "index_responses_on_interest"
    remove_index :responses, name: "index_responses_on_contribution"
    remove_index :responses, name: "index_responses_on_learning"
  end
end
