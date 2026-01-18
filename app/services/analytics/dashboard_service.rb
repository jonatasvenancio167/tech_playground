module Analytics
  class DashboardService
    def initialize(filters = {})
      @filters = filters
      @responses_scope = build_responses_scope
      @employees_scope = build_employees_scope
    end

    # Dashboard completo da empresa
    def company_overview
      {
        participation: participation_metrics,
        enps: nps_metrics,
        favorability: favorability_metrics,
        demographics: demographic_metrics,
        timestamp: Time.current
      }
    end

    # Dashboard por departamento
    def department_breakdown
      departments = Employee.distinct.pluck(:department).compact

      departments.map do |dept|
        scope = @responses_scope.joins(:employee).where(employees: { department: dept })
        emp_scope = Employee.where(department: dept)

        {
          department: dept,
          participation: participation_for_scope(emp_scope, scope),
          enps: NpsService.new(scope).calculate,
          favorability: FavorabilityService.new(scope).overall_favorability,
          total_employees: emp_scope.count,
          total_responses: scope.count
        }
      end.sort_by { |d| -d[:enps][:score] }
    end

    # Métricas de tendência (últimos N meses)
    def trends(months: 6)
      {
        enps_trend: NpsService.new(@responses_scope).trend(period: :month, limit: months),
        response_trend: response_volume_trend(months),
        favorability_trend: favorability_trend(months)
      }
    end

    # Identifica áreas de atenção
    def attention_areas
      {
        at_risk_departments: at_risk_departments,
        low_favorability_dimensions: low_favorability_dimensions,
        low_participation_departments: low_participation_departments,
        at_risk_employees: at_risk_employees_count
      }
    end

    # Sumário executivo
    def executive_summary
      nps = nps_metrics
      fav_service = FavorabilityService.new(@responses_scope)

      {
        headline_metrics: {
          total_employees: @employees_scope.count,
          response_rate: participation_metrics[:response_rate],
          enps_score: nps[:score],
          enps_level: nps[:level],
          overall_favorability: fav_service.overall_favorability
        },
        top_strengths: fav_service.top_strengths(3),
        improvement_areas: fav_service.improvement_areas(3),
        critical_alerts: critical_alerts,
        generated_at: Time.current
      }
    end

    private

    def build_responses_scope
      scope = Response.all

      if @filters[:date_from].present?
        scope = scope.where("response_date >= ?", @filters[:date_from])
      end

      if @filters[:date_to].present?
        scope = scope.where("response_date <= ?", @filters[:date_to])
      end

      if @filters[:department].present?
        scope = scope.joins(:employee).where(employees: { department: @filters[:department] })
      end

      if @filters[:location].present?
        scope = scope.joins(:employee).where(employees: { location: @filters[:location] })
      end

      scope
    end

    def build_employees_scope
      scope = Employee.all

      scope = scope.where(department: @filters[:department]) if @filters[:department].present?
      scope = scope.where(location: @filters[:location]) if @filters[:location].present?

      scope
    end

    def participation_metrics
      total_employees = @employees_scope.count
      employees_with_responses = @employees_scope.joins(:responses)
                                                 .where(responses: { id: @responses_scope.select(:id) })
                                                 .distinct
                                                 .count

      total_responses = @responses_scope.count

      {
        total_employees: total_employees,
        employees_responded: employees_with_responses,
        total_responses: total_responses,
        response_rate: total_employees.zero? ? 0.0 : (employees_with_responses.to_f / total_employees * 100).round(2),
        engagement_level: engagement_level(employees_with_responses, total_employees)
      }
    end

    def participation_for_scope(emp_scope, resp_scope)
      total = emp_scope.count
      responded = emp_scope.joins(:responses)
                          .where(responses: { id: resp_scope.select(:id) })
                          .distinct
                          .count

      {
        total_employees: total,
        employees_responded: responded,
        response_rate: total.zero? ? 0.0 : (responded.to_f / total * 100).round(2)
      }
    end

    def nps_metrics
      NpsService.new(@responses_scope).calculate
    end

    def favorability_metrics
      FavorabilityService.new(@responses_scope).calculate_all
    end

    def demographic_metrics
      {
        by_department: department_distribution,
        by_location: location_distribution,
        by_generation: generation_distribution
      }
    end

    def department_distribution
      @employees_scope.group(:department).count
    end

    def location_distribution
      @employees_scope.group(:location).count
    end

    def generation_distribution
      @employees_scope.group(:generation).count
    end

    def engagement_level(responded, total)
      rate = total.zero? ? 0 : (responded.to_f / total * 100)

      case rate
      when 0..30 then "low"
      when 30..60 then "medium"
      when 60..80 then "good"
      else "excellent"
      end
    end

    def at_risk_departments
      NpsService.at_risk_departments.map do |dept, metrics|
        {
          department: dept,
          enps_score: metrics[:score],
          detractors_count: metrics[:detractors][:count],
          total_responses: metrics[:total_responses]
        }
      end
    end

    def low_favorability_dimensions(threshold = 60)
      FavorabilityService.new(@responses_scope).below_threshold(threshold)
    end

    def low_participation_departments(threshold = 50)
      departments = Employee.distinct.pluck(:department).compact

      departments.filter_map do |dept|
        emp_scope = Employee.where(department: dept)
        resp_scope = @responses_scope.joins(:employee).where(employees: { department: dept })

        total = emp_scope.count
        responded = emp_scope.joins(:responses)
                            .where(responses: { id: resp_scope.select(:id) })
                            .distinct
                            .count

        rate = total.zero? ? 0 : (responded.to_f / total * 100).round(2)

        if rate < threshold
          {
            department: dept,
            total_employees: total,
            responded: responded,
            response_rate: rate
          }
        end
      end
    end

    def at_risk_employees_count
      @responses_scope.select(&:at_risk?).count
    end

    def response_volume_trend(months)
      @responses_scope
        .group_by_month(:response_date, last: months)
        .count
        .map { |date, count| { period: date, count: count } }
    end

    def favorability_trend(months)
      {
        note: "Feature not fully implemented - requires time-series favorability calculation"
      }
    end

    def critical_alerts
      alerts = []

      # eNPS crítico
      nps = nps_metrics
      if nps[:score] < 0
        alerts << {
          type: "critical_enps",
          message: "eNPS score is negative (#{nps[:score]})",
          severity: "high"
        }
      end

      # Departamentos em risco
      at_risk = at_risk_departments
      unless at_risk.empty?
        alerts << {
          type: "at_risk_departments",
          message: "#{at_risk.count} department(s) with negative eNPS",
          severity: "high",
          details: at_risk
        }
      end

      # Baixa participação
      participation = participation_metrics
      if participation[:response_rate] < 50
        alerts << {
          type: "low_participation",
          message: "Response rate below 50% (#{participation[:response_rate]}%)",
          severity: "medium"
        }
      end

      alerts
    end
  end
end
