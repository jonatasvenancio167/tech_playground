require 'caxlsx'

module Reports
  class ExcelReport < BaseReport
    def format
      :xlsx
    end

    def generate
      package = Axlsx::Package.new

      add_overview_sheet(package)
      add_enps_sheet(package)
      add_favorability_sheet(package)
      add_departments_sheet(package)
      add_raw_data_sheet(package)

      @data = package.to_stream.read
      self
    end

    private

    def add_overview_sheet(package)
      package.workbook.add_worksheet(name: "Overview") do |sheet|

        sheet.add_row ["Tech Playground Analytics Report"], style: title_style(package)
        sheet.add_row ["Generated: #{Time.current.strftime('%Y-%m-%d %H:%M')}"]
        sheet.add_row []

        service = Analytics::DashboardService.new(@filters)
        summary = service.executive_summary
        metrics = summary[:headline_metrics]

        sheet.add_row ["Executive Summary"], style: header_style(package)
        sheet.add_row ["Metric", "Value"], style: subheader_style(package)
        sheet.add_row ["Total Employees", metrics[:total_employees]]
        sheet.add_row ["Response Rate", "#{metrics[:response_rate]}%"]
        sheet.add_row ["eNPS Score", metrics[:enps_score]]
        sheet.add_row ["eNPS Level", metrics[:enps_level].titleize]
        sheet.add_row ["Overall Favorability", "#{metrics[:overall_favorability]}%"]
        sheet.add_row []

        sheet.add_row ["Top 3 Strengths"], style: header_style(package)
        sheet.add_row ["Dimension", "Percentage"], style: subheader_style(package)
        summary[:top_strengths].each do |dimension, data|
          sheet.add_row [dimension.to_s.titleize, "#{data[:percentage]}%"]
        end
        sheet.add_row []

        sheet.add_row ["Top 3 Improvement Areas"], style: header_style(package)
        sheet.add_row ["Dimension", "Percentage"], style: subheader_style(package)
        summary[:improvement_areas].each do |dimension, data|
          sheet.add_row [dimension.to_s.titleize, "#{data[:percentage]}%"]
        end

        sheet.column_widths 30, 20
      end
    end

    def add_enps_sheet(package)
      package.workbook.add_worksheet(name: "eNPS Analysis") do |sheet|
        service = Analytics::NpsService.new(apply_filters(Response.all))
        nps_data = service.calculate

        sheet.add_row ["eNPS Analysis"], style: title_style(package)
        sheet.add_row []

        sheet.add_row ["Overall eNPS Score", nps_data[:score]], style: highlight_style(package)
        sheet.add_row ["Level", nps_data[:level].titleize]
        sheet.add_row ["Average Score (0-10)", nps_data[:average_score]]
        sheet.add_row ["Total Responses", nps_data[:total_responses]]
        sheet.add_row []

        sheet.add_row ["Distribution"], style: header_style(package)
        sheet.add_row ["Category", "Count", "Percentage"], style: subheader_style(package)
        sheet.add_row ["Promoters (9-10)", nps_data[:promoters][:count], "#{nps_data[:promoters][:percentage]}%"]
        sheet.add_row ["Passives (7-8)", nps_data[:passives][:count], "#{nps_data[:passives][:percentage]}%"]
        sheet.add_row ["Detractors (0-6)", nps_data[:detractors][:count], "#{nps_data[:detractors][:percentage]}%"]
        sheet.add_row []

        unless @filters[:department].present?
          sheet.add_row ["eNPS by Department"], style: header_style(package)
          sheet.add_row ["Department", "eNPS Score", "Promoters", "Passives", "Detractors"], style: subheader_style(package)

          dept_nps = Analytics::NpsService.by_department
          dept_nps.each do |dept, data|
            sheet.add_row [
              dept.titleize,
              data[:score],
              data[:promoters][:count],
              data[:passives][:count],
              data[:detractors][:count]
            ]
          end
        end

        sheet.column_widths 25, 15, 15, 15, 15
      end
    end

    def add_favorability_sheet(package)
      package.workbook.add_worksheet(name: "Favorability") do |sheet|
        service = Analytics::FavorabilityService.new(apply_filters(Response.all))
        fav_data = service.calculate_all

        sheet.add_row ["Favorability Analysis"], style: title_style(package)
        sheet.add_row ["Overall Favorability", "#{service.overall_favorability}%"], style: highlight_style(package)
        sheet.add_row []

        sheet.add_row ["By Dimension"], style: header_style(package)
        sheet.add_row ["Dimension", "Favorable", "Unfavorable", "Total", "Percentage"], style: subheader_style(package)

        fav_data.sort_by { |_, v| -v[:percentage] }.each do |dimension, data|
          sheet.add_row [
            dimension.to_s.titleize,
            data[:favorable_count],
            data[:unfavorable_count],
            data[:total_count],
            "#{data[:percentage]}%"
          ]
        end
        sheet.add_row []

        unless @filters[:department].present?
          sheet.add_row ["Favorability by Department"], style: header_style(package)

          dept_fav = Analytics::FavorabilityService.by_department
          departments = dept_fav.keys

          headers = ["Dimension"] + departments.map(&:titleize)
          sheet.add_row headers, style: subheader_style(package)

          Analytics::FavorabilityService::DIMENSIONS.each do |dimension|
            row_data = [dimension.to_s.titleize]
            departments.each do |dept|
              percentage = dept_fav[dept][dimension][:percentage]
              row_data << "#{percentage}%"
            end
            sheet.add_row row_data
          end
        end

        sheet.column_widths 35, 12, 12, 12, 12
      end
    end

    def add_departments_sheet(package)
      return if @filters[:department].present?

      package.workbook.add_worksheet(name: "Departments") do |sheet|
        service = Analytics::DashboardService.new(@filters)
        departments = service.department_breakdown

        sheet.add_row ["Department Breakdown"], style: title_style(package)
        sheet.add_row []

        sheet.add_row [
          "Department",
          "Total Employees",
          "Responses",
          "Response Rate",
          "eNPS Score",
          "eNPS Level",
          "Promoters",
          "Passives",
          "Detractors",
          "Favorability"
        ], style: subheader_style(package)

        departments.each do |dept|
          sheet.add_row [
            dept[:department].titleize,
            dept[:total_employees],
            dept[:total_responses],
            "#{dept[:participation][:response_rate]}%",
            dept[:enps][:score],
            dept[:enps][:level].titleize,
            dept[:enps][:promoters][:count],
            dept[:enps][:passives][:count],
            dept[:enps][:detractors][:count],
            "#{dept[:favorability]}%"
          ]
        end

        sheet.column_widths 20, 12, 12, 12, 10, 15, 10, 10, 10, 12
      end
    end

    def add_raw_data_sheet(package)
      package.workbook.add_worksheet(name: "Raw Data") do |sheet|
        scope = apply_filters(Response.all).includes(:employee)

        headers = [
          "Response Date",
          "Employee Name",
          "Department",
          "Location",
          "Interest in Position",
          "Contribution",
          "Learning & Development",
          "Feedback",
          "Manager Interaction",
          "Career Clarity",
          "Permanence",
          "eNPS",
          "eNPS Category"
        ]
        sheet.add_row headers, style: subheader_style(package)

        scope.find_each do |response|
          sheet.add_row [
            response.response_date,
            response.employee.name,
            response.employee.department,
            response.employee.location,
            response.interest_in_position,
            response.contribution,
            response.learning_and_development,
            response.feedback,
            response.interaction_with_manager,
            response.career_opportunity_clarity,
            response.permanence_expectation,
            response.enps,
            response.enps_category
          ]
        end

        sheet.column_widths 12, 20, 15, 15, 12, 12, 12, 12, 12, 12, 12, 8, 12
      end
    end

    def title_style(package)
      package.workbook.styles.add_style(
        sz: 16,
        b: true,
        fg_color: '0066CC'
      )
    end

    def header_style(package)
      package.workbook.styles.add_style(
        sz: 14,
        b: true,
        fg_color: '333333'
      )
    end

    def subheader_style(package)
      package.workbook.styles.add_style(
        sz: 12,
        b: true,
        bg_color: 'EEEEEE',
        border: { style: :thin, color: '000000' }
      )
    end

    def highlight_style(package)
      package.workbook.styles.add_style(
        sz: 14,
        b: true,
        bg_color: 'FFEB3B'
      )
    end
  end
end
