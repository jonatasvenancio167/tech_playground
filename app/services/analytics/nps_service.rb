module Analytics
  class NpsService
    # Categorias eNPS
    # Promoters: 9-10
    # Passives: 7-8
    # Detractors: 0-6

    def initialize(scope = Response.all)
      @scope = scope.where.not(enps: nil)
    end

    # Calcula o eNPS score
    # Formula: (% Promoters) - (% Detractors)
    def calculate
      total = @scope.count
      return default_result if total.zero?

      promoters = @scope.promoters.count
      passives = @scope.passives.count
      detractors = @scope.detractors.count

      promoters_pct = (promoters.to_f / total * 100).round(2)
      passives_pct = (passives.to_f / total * 100).round(2)
      detractors_pct = (detractors.to_f / total * 100).round(2)

      score = promoters_pct - detractors_pct

      {
        score: score.round(2),
        level: categorize_score(score),
        total_responses: total,
        promoters: {
          count: promoters,
          percentage: promoters_pct
        },
        passives: {
          count: passives,
          percentage: passives_pct
        },
        detractors: {
          count: detractors,
          percentage: detractors_pct
        },
        average_score: @scope.average(:enps)&.round(2) || 0.0
      }
    end

    # Distribui respostas por score eNPS
    def distribution
      (0..10).map do |score|
        {
          score: score,
          count: @scope.where(enps: score).count,
          category: categorize_enps(score)
        }
      end
    end

    # Tendência do eNPS ao longo do tempo
    def trend(period: :month, limit: 12)
      groups = @scope.group_by_period(period, :response_date, last: limit)
                     .select("
                       COUNT(*) as total,
                       COUNT(CASE WHEN enps >= 9 THEN 1 END) as promoters,
                       COUNT(CASE WHEN enps <= 6 THEN 1 END) as detractors
                     ")

      result = []
      groups.each do |date, metrics|
        next if metrics.nil?
        total = metrics["total"].to_f
        next if total.zero?

        promoters_pct = (metrics["promoters"].to_f / total * 100)
        detractors_pct = (metrics["detractors"].to_f / total * 100)
        score = promoters_pct - detractors_pct

        result << {
          period: date,
          score: score.round(2),
          level: categorize_score(score),
          total_responses: total.to_i
        }
      end

      result
    end

    # eNPS segmentado
    def self.by_segment(segment_field, segment_value = nil)
      if segment_value
        scope = Response.joins(:employee).where(employees: { segment_field => segment_value })
        new(scope)
      else
        segments = Employee.distinct.pluck(segment_field).compact
        result = {}

        segments.each do |value|
          scope = Response.joins(:employee).where(employees: { segment_field => value })
          result[value] = new(scope).calculate
        end

        result.sort_by { |_, v| -v[:score] }.to_h
      end
    end

    # eNPS por departamento
    def self.by_department(department = nil)
      by_segment(:department, department)
    end

    # eNPS por localidade
    def self.by_location(location = nil)
      by_segment(:location, location)
    end

    # eNPS por geração
    def self.by_generation(generation = nil)
      by_segment(:generation, generation)
    end

    # Identifica segmentos em risco (eNPS < 0)
    def self.at_risk_segments(segment_field)
      all_segments = by_segment(segment_field)
      all_segments.select { |_, metrics| metrics[:score] < 0 }
    end

    # Identifica departamentos em risco
    def self.at_risk_departments
      at_risk_segments(:department)
    end

    private

    def default_result
      {
        score: 0.0,
        level: "no_data",
        total_responses: 0,
        promoters: { count: 0, percentage: 0.0 },
        passives: { count: 0, percentage: 0.0 },
        detractors: { count: 0, percentage: 0.0 },
        average_score: 0.0
      }
    end

    def categorize_score(score)
      case score
      when -100..-1 then "critical"
      when 0..30 then "needs_improvement"
      when 30..50 then "good"
      when 50..70 then "very_good"
      else "excellent"
      end
    end

    def categorize_enps(score)
      case score
      when 9..10 then "promoter"
      when 7..8 then "passive"
      when 0..6 then "detractor"
      end
    end
  end
end
