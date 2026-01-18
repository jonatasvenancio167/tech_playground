class CreateAnalyticsMaterializedViews < ActiveRecord::Migration[8.1]
  def up
    # View materializada para métricas por departamento
    execute <<-SQL
      CREATE MATERIALIZED VIEW department_analytics AS
      SELECT
        e.department,
        COUNT(DISTINCT e.id) as total_employees,
        COUNT(DISTINCT r.id) as total_responses,
        ROUND(COUNT(DISTINCT r.id)::numeric / NULLIF(COUNT(DISTINCT e.id), 0) * 100, 2) as response_rate,

        -- Médias de cada dimensão
        ROUND(AVG(r.interest_in_position)::numeric, 2) as avg_interest_in_position,
        ROUND(AVG(r.contribution)::numeric, 2) as avg_contribution,
        ROUND(AVG(r.learning_and_development)::numeric, 2) as avg_learning_and_development,
        ROUND(AVG(r.feedback)::numeric, 2) as avg_feedback,
        ROUND(AVG(r.interaction_with_manager)::numeric, 2) as avg_interaction_with_manager,
        ROUND(AVG(r.career_opportunity_clarity)::numeric, 2) as avg_career_opportunity_clarity,
        ROUND(AVG(r.permanence_expectation)::numeric, 2) as avg_permanence_expectation,

        -- Favorabilidade (% de respostas >= 6, escala 1-7)
        ROUND(COUNT(CASE WHEN r.interest_in_position >= 6 THEN 1 END)::numeric / NULLIF(COUNT(r.interest_in_position), 0) * 100, 2) as favorability_interest,
        ROUND(COUNT(CASE WHEN r.contribution >= 6 THEN 1 END)::numeric / NULLIF(COUNT(r.contribution), 0) * 100, 2) as favorability_contribution,
        ROUND(COUNT(CASE WHEN r.learning_and_development >= 6 THEN 1 END)::numeric / NULLIF(COUNT(r.learning_and_development), 0) * 100, 2) as favorability_learning,
        ROUND(COUNT(CASE WHEN r.feedback >= 6 THEN 1 END)::numeric / NULLIF(COUNT(r.feedback), 0) * 100, 2) as favorability_feedback,
        ROUND(COUNT(CASE WHEN r.interaction_with_manager >= 6 THEN 1 END)::numeric / NULLIF(COUNT(r.interaction_with_manager), 0) * 100, 2) as favorability_manager,
        ROUND(COUNT(CASE WHEN r.career_opportunity_clarity >= 6 THEN 1 END)::numeric / NULLIF(COUNT(r.career_opportunity_clarity), 0) * 100, 2) as favorability_career,
        ROUND(COUNT(CASE WHEN r.permanence_expectation >= 6 THEN 1 END)::numeric / NULLIF(COUNT(r.permanence_expectation), 0) * 100, 2) as favorability_permanence,

        -- eNPS metrics
        ROUND(AVG(r.enps)::numeric, 2) as avg_enps,
        COUNT(CASE WHEN r.enps >= 9 THEN 1 END) as promoters_count,
        COUNT(CASE WHEN r.enps BETWEEN 7 AND 8 THEN 1 END) as passives_count,
        COUNT(CASE WHEN r.enps <= 6 THEN 1 END) as detractors_count,
        ROUND((COUNT(CASE WHEN r.enps >= 9 THEN 1 END)::numeric / NULLIF(COUNT(r.enps), 0) * 100) -
              (COUNT(CASE WHEN r.enps <= 6 THEN 1 END)::numeric / NULLIF(COUNT(r.enps), 0) * 100), 2) as enps_score,

        -- Timestamps
        MAX(r.response_date) as last_response_date,
        CURRENT_TIMESTAMP as calculated_at
      FROM employees e
      LEFT JOIN responses r ON r.employee_id = e.id
      WHERE e.department IS NOT NULL
      GROUP BY e.department;
    SQL

    # Criar índice na view materializada
    add_index :department_analytics, :department, unique: true

    # View materializada para métricas por localidade
    execute <<-SQL
      CREATE MATERIALIZED VIEW location_analytics AS
      SELECT
        e.location,
        COUNT(DISTINCT e.id) as total_employees,
        COUNT(DISTINCT r.id) as total_responses,
        ROUND(COUNT(DISTINCT r.id)::numeric / NULLIF(COUNT(DISTINCT e.id), 0) * 100, 2) as response_rate,

        -- Médias gerais
        ROUND(AVG(r.interest_in_position)::numeric, 2) as avg_interest_in_position,
        ROUND(AVG(r.contribution)::numeric, 2) as avg_contribution,
        ROUND(AVG(r.learning_and_development)::numeric, 2) as avg_learning_and_development,
        ROUND(AVG(r.feedback)::numeric, 2) as avg_feedback,
        ROUND(AVG(r.interaction_with_manager)::numeric, 2) as avg_interaction_with_manager,
        ROUND(AVG(r.career_opportunity_clarity)::numeric, 2) as avg_career_opportunity_clarity,
        ROUND(AVG(r.permanence_expectation)::numeric, 2) as avg_permanence_expectation,

        -- eNPS
        ROUND(AVG(r.enps)::numeric, 2) as avg_enps,
        ROUND((COUNT(CASE WHEN r.enps >= 9 THEN 1 END)::numeric / NULLIF(COUNT(r.enps), 0) * 100) -
              (COUNT(CASE WHEN r.enps <= 6 THEN 1 END)::numeric / NULLIF(COUNT(r.enps), 0) * 100), 2) as enps_score,

        CURRENT_TIMESTAMP as calculated_at
      FROM employees e
      LEFT JOIN responses r ON r.employee_id = e.id
      WHERE e.location IS NOT NULL
      GROUP BY e.location;
    SQL

    add_index :location_analytics, :location, unique: true

    # View materializada para overview geral da empresa
    execute <<-SQL
      CREATE MATERIALIZED VIEW company_analytics AS
      SELECT
        COUNT(DISTINCT e.id) as total_employees,
        COUNT(DISTINCT r.id) as total_responses,
        ROUND(COUNT(DISTINCT r.id)::numeric / NULLIF(COUNT(DISTINCT e.id), 0) * 100, 2) as response_rate,

        -- Médias globais
        ROUND(AVG(r.interest_in_position)::numeric, 2) as avg_interest_in_position,
        ROUND(AVG(r.contribution)::numeric, 2) as avg_contribution,
        ROUND(AVG(r.learning_and_development)::numeric, 2) as avg_learning_and_development,
        ROUND(AVG(r.feedback)::numeric, 2) as avg_feedback,
        ROUND(AVG(r.interaction_with_manager)::numeric, 2) as avg_interaction_with_manager,
        ROUND(AVG(r.career_opportunity_clarity)::numeric, 2) as avg_career_opportunity_clarity,
        ROUND(AVG(r.permanence_expectation)::numeric, 2) as avg_permanence_expectation,

        -- Favorabilidade global (% de respostas >= 6, escala 1-7)
        ROUND(COUNT(CASE WHEN r.interest_in_position >= 6 THEN 1 END)::numeric / NULLIF(COUNT(r.interest_in_position), 0) * 100, 2) as favorability_interest,
        ROUND(COUNT(CASE WHEN r.contribution >= 6 THEN 1 END)::numeric / NULLIF(COUNT(r.contribution), 0) * 100, 2) as favorability_contribution,
        ROUND(COUNT(CASE WHEN r.learning_and_development >= 6 THEN 1 END)::numeric / NULLIF(COUNT(r.learning_and_development), 0) * 100, 2) as favorability_learning,
        ROUND(COUNT(CASE WHEN r.feedback >= 6 THEN 1 END)::numeric / NULLIF(COUNT(r.feedback), 0) * 100, 2) as favorability_feedback,
        ROUND(COUNT(CASE WHEN r.interaction_with_manager >= 6 THEN 1 END)::numeric / NULLIF(COUNT(r.interaction_with_manager), 0) * 100, 2) as favorability_manager,
        ROUND(COUNT(CASE WHEN r.career_opportunity_clarity >= 6 THEN 1 END)::numeric / NULLIF(COUNT(r.career_opportunity_clarity), 0) * 100, 2) as favorability_career,
        ROUND(COUNT(CASE WHEN r.permanence_expectation >= 6 THEN 1 END)::numeric / NULLIF(COUNT(r.permanence_expectation), 0) * 100, 2) as favorability_permanence,

        -- eNPS global
        ROUND(AVG(r.enps)::numeric, 2) as avg_enps,
        COUNT(CASE WHEN r.enps >= 9 THEN 1 END) as promoters_count,
        COUNT(CASE WHEN r.enps BETWEEN 7 AND 8 THEN 1 END) as passives_count,
        COUNT(CASE WHEN r.enps <= 6 THEN 1 END) as detractors_count,
        ROUND((COUNT(CASE WHEN r.enps >= 9 THEN 1 END)::numeric / NULLIF(COUNT(r.enps), 0) * 100) -
              (COUNT(CASE WHEN r.enps <= 6 THEN 1 END)::numeric / NULLIF(COUNT(r.enps), 0) * 100), 2) as enps_score,

        -- Estatísticas adicionais
        COUNT(DISTINCT e.department) as total_departments,
        COUNT(DISTINCT e.location) as total_locations,

        CURRENT_TIMESTAMP as calculated_at
      FROM employees e
      LEFT JOIN responses r ON r.employee_id = e.id;
    SQL
  end

  def down
    execute "DROP MATERIALIZED VIEW IF EXISTS company_analytics;"
    execute "DROP MATERIALIZED VIEW IF EXISTS location_analytics;"
    execute "DROP MATERIALIZED VIEW IF EXISTS department_analytics;"
  end
end
