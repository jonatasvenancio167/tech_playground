require 'prawn'
require 'prawn/table'

module Reports
  class PdfReport < BaseReport
    def format
      :pdf
    end

    def generate
      pdf = Prawn::Document.new(page_size: 'A4', margin: 40)

      add_header(pdf)
      add_executive_summary(pdf)
      add_enps_section(pdf)
      add_favorability_section(pdf)
      add_departments_section(pdf)
      add_footer(pdf)

      @data = pdf.render
      self
    end

    private

    def add_header(pdf)
      pdf.text "Tech Playground Analytics Report", size: 24, style: :bold, color: '0066CC'
      pdf.text "Employee Feedback Analysis", size: 14, color: '666666'
      pdf.move_down 5
      pdf.text "Generated: #{Time.current.strftime('%B %d, %Y at %H:%M')}", size: 10, color: '999999'

      if @filters.any?
        pdf.move_down 5
        pdf.text "Filters: #{format_filters}", size: 10, color: '999999'
      end

      pdf.stroke_horizontal_rule
      pdf.move_down 20
    end

    def add_executive_summary(pdf)
      service = Analytics::DashboardService.new(@filters)
      summary = service.executive_summary

      pdf.text "Executive Summary", size: 18, style: :bold
      pdf.move_down 10

      metrics = summary[:headline_metrics]
      data = [
        ['Metric', 'Value'],
        ['Total Employees', metrics[:total_employees].to_s],
        ['Response Rate', "#{metrics[:response_rate]}%"],
        ['eNPS Score', metrics[:enps_score].to_s],
        ['eNPS Level', metrics[:enps_level].titleize],
        ['Overall Favorability', "#{metrics[:overall_favorability]}%"]
      ]

      pdf.table(data, width: pdf.bounds.width, header: true) do
        row(0).font_style = :bold
        row(0).background_color = 'EEEEEE'
        cells.padding = 8
        cells.borders = [:top, :bottom]
      end

      pdf.move_down 20

      pdf.text "Top 3 Strengths", size: 14, style: :bold
      pdf.move_down 5

      summary[:top_strengths].each do |dimension, data|
        pdf.text "• #{dimension.to_s.titleize}: #{data[:percentage]}%", size: 11
        pdf.move_down 3
      end

      pdf.move_down 10

      pdf.text "Top 3 Improvement Areas", size: 14, style: :bold
      pdf.move_down 5

      summary[:improvement_areas].each do |dimension, data|
        pdf.text "• #{dimension.to_s.titleize}: #{data[:percentage]}%", size: 11, color: 'CC0000'
        pdf.move_down 3
      end

      pdf.move_down 20
    end

    def add_enps_section(pdf)
      pdf.start_new_page

      pdf.text "eNPS Analysis", size: 18, style: :bold
      pdf.move_down 10

      service = Analytics::NpsService.new(apply_filters(Response.all))
      nps_data = service.calculate

      pdf.text "Overall Score: #{nps_data[:score]}", size: 16, style: :bold, color: enps_color(nps_data[:score])
      pdf.text "Level: #{nps_data[:level].titleize}", size: 12
      pdf.move_down 10

      data = [
        ['Category', 'Count', 'Percentage'],
        ['Promoters (9-10)', nps_data[:promoters][:count].to_s, "#{nps_data[:promoters][:percentage]}%"],
        ['Passives (7-8)', nps_data[:passives][:count].to_s, "#{nps_data[:passives][:percentage]}%"],
        ['Detractors (0-6)', nps_data[:detractors][:count].to_s, "#{nps_data[:detractors][:percentage]}%"]
      ]

      pdf.table(data, width: pdf.bounds.width, header: true) do
        row(0).font_style = :bold
        row(0).background_color = 'EEEEEE'
        row(1).background_color = 'D4EDDA'
        row(2).background_color = 'FFF3CD'
        row(3).background_color = 'F8D7DA'
        cells.padding = 8
      end

      pdf.move_down 15

      pdf.text "Interpretation", size: 14, style: :bold
      pdf.move_down 5
      pdf.text interpretation_text(nps_data[:score]), size: 11, leading: 4
    end

    def add_favorability_section(pdf)
      pdf.move_down 20

      pdf.text "Favorability Analysis", size: 18, style: :bold
      pdf.move_down 10

      service = Analytics::FavorabilityService.new(apply_filters(Response.all))
      fav_data = service.calculate_all

      table_data = [['Dimension', 'Favorable', 'Total', 'Percentage']]

      fav_data.sort_by { |_, v| -v[:percentage] }.each do |dimension, data|
        table_data << [
          dimension.to_s.titleize,
          data[:favorable_count].to_s,
          data[:total_count].to_s,
          "#{data[:percentage]}%"
        ]
      end

      pdf.table(table_data, width: pdf.bounds.width, header: true) do
        row(0).font_style = :bold
        row(0).background_color = 'EEEEEE'
        cells.padding = 8

        (1...table_data.length).each do |i|
          percentage = table_data[i][3].to_f
          row(i).background_color = favorability_bg_color(percentage)
        end
      end
    end

    def add_departments_section(pdf)
      return if @filters[:department].present?

      pdf.start_new_page

      pdf.text "Department Breakdown", size: 18, style: :bold
      pdf.move_down 10

      service = Analytics::DashboardService.new(@filters)
      departments = service.department_breakdown

      table_data = [['Department', 'Employees', 'Response Rate', 'eNPS', 'Favorability']]

      departments.each do |dept|
        table_data << [
          dept[:department].titleize,
          dept[:total_employees].to_s,
          "#{dept[:participation][:response_rate]}%",
          dept[:enps][:score].to_s,
          "#{dept[:favorability]}%"
        ]
      end

      pdf.table(table_data, width: pdf.bounds.width, header: true) do
        row(0).font_style = :bold
        row(0).background_color = 'EEEEEE'
        cells.padding = 8
      end
    end

    def add_footer(pdf)
      pdf.repeat(:all) do
        pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom + 20], width: pdf.bounds.width) do
          pdf.font_size 8
          pdf.text "Tech Playground Analytics • Page #{pdf.page_number}", align: :center, color: '999999'
        end
      end
    end

    def format_filters
      @filters.map { |k, v| "#{k.to_s.titleize}: #{v}" }.join(', ')
    end

    def enps_color(score)
      case score.to_f
      when 70.. then '10B981'
      when 50...70 then '3B82F6'
      when 30...50 then 'F59E0B'
      when 0...30 then 'EF4444'
      else 'DC2626'
      end
    end

    def favorability_bg_color(percentage)
      case percentage.to_f
      when 80.. then 'D4EDDA'
      when 60...80 then 'D1ECF1'
      when 40...60 then 'FFF3CD'
      else 'F8D7DA'
      end
    end

    def interpretation_text(score)
      case score.to_f
      when 70..
        "Excellent! The company has an outstanding eNPS score. Employees are highly likely to recommend the company as a great place to work."
      when 50...70
        "Very Good. The company shows strong employee advocacy with significantly more promoters than detractors."
      when 30...50
        "Good. There's a positive sentiment overall, but there's room for improvement to reach excellence."
      when 0...30
        "Needs Improvement. While the score is positive, focus should be placed on addressing employee concerns and increasing satisfaction."
      else
        "Critical. Immediate action is required. There are more detractors than promoters, indicating significant employee dissatisfaction."
      end
    end
  end
end
