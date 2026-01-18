module Analytics
  class FavorabilityService
    # Favorável = respostas >= 6 em escala Likert 1-7 (conforme dados do CSV)
    FAVORABLE_THRESHOLD = 6

    DIMENSIONS = %i[
      interest_in_position
      contribution
      learning_and_development
      feedback
      interaction_with_manager
      career_opportunity_clarity
      permanence_expectation
    ].freeze

    def initialize(scope = Response.all)
      @scope = scope
    end

    # Calcula favorabilidade para todas as dimensões
    def calculate_all
      result = {}
      DIMENSIONS.each do |dimension|
        result[dimension] = calculate_dimension(dimension)
      end
      result
    end

    # Calcula favorabilidade para uma dimensão específica
    def calculate_dimension(dimension)
      total = @scope.where.not(dimension => nil).count

      if total.zero?
        return {
          percentage: 0.0,
          favorable_count: 0,
          total_count: 0,
          unfavorable_count: 0
        }
      end

      favorable = @scope.where("#{dimension} >= ?", FAVORABLE_THRESHOLD).count
      percentage = (favorable.to_f / total * 100).round(2)

      {
        percentage: percentage,
        favorable_count: favorable,
        total_count: total,
        unfavorable_count: total - favorable
      }
    end

    # Retorna as dimensões ordenadas por favorabilidade
    def ranking
      all_dimensions = calculate_all
      # Filtra apenas valores que são Hashes válidos com :percentage
      valid_dimensions = all_dimensions.select { |_, v| v.is_a?(Hash) && v.key?(:percentage) }
      valid_dimensions.sort_by { |_, v| -v[:percentage] }.to_h
    end

    # Top N dimensões com melhor favorabilidade
    def top_strengths(n = 3)
      ranked = ranking.to_a
      ranked.first(n).to_h
    end

    # Top N dimensões que precisam de atenção (piores)
    def improvement_areas(n = 3)
      ranked = ranking.to_a
      ranked.last(n).reverse.to_h
    end

    # Identifica dimensões abaixo de um threshold
    def below_threshold(threshold = 60)
      all_dimensions = calculate_all
      all_dimensions.select { |_, v| v.is_a?(Hash) && v[:percentage] < threshold }
    end

    # Favorabilidade média geral
    def overall_favorability
      all_dimensions = calculate_all
      all_favs = all_dimensions.values
                               .select { |v| v.is_a?(Hash) && v.key?(:percentage) }
                               .map { |v| v[:percentage] }
      return 0.0 if all_favs.empty?

      (all_favs.sum / all_favs.size).round(2)
    end

    # Calcula favorabilidade segmentada (por departamento, localidade, etc.)
    def self.by_segment(segment_field, segment_value = nil)
      if segment_value
        scope = Response.joins(:employee).where(employees: { segment_field => segment_value })
        new(scope)
      else
        # Retorna hash com favorabilidade para cada valor do segmento
        segments = Employee.distinct.pluck(segment_field).compact
        result = {}

        segments.each do |value|
          scope = Response.joins(:employee).where(employees: { segment_field => value })
          result[value] = new(scope).calculate_all
        end

        result
      end
    end

    # Favorabilidade por departamento
    def self.by_department(department = nil)
      by_segment(:department, department)
    end

    # Favorabilidade por localidade
    def self.by_location(location = nil)
      by_segment(:location, location)
    end

    # Favorabilidade por geração
    def self.by_generation(generation = nil)
      by_segment(:generation, generation)
    end
  end
end
