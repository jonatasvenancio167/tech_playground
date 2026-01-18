namespace :analytics do
  desc "Refresh all materialized views for analytics"
  task refresh: :environment do
    puts "Refreshing analytics materialized views..."

    begin
      Benchmark.bm(30) do |x|
        x.report("Department Analytics:") do
          DepartmentAnalytic.refresh!
        end

        x.report("Location Analytics:") do
          LocationAnalytic.refresh!
        end

        x.report("Company Analytics:") do
          CompanyAnalytic.refresh!
        end
      end

      puts "\n✓ All analytics views refreshed successfully!"
    rescue => e
      puts "\n✗ Error refreshing views: #{e.message}"
      raise e
    end
  end

  desc "Show company analytics summary"
  task summary: :environment do
    analytics = CompanyAnalytic.current

    if analytics.nil?
      puts "No analytics data available. Run 'rails analytics:refresh' first."
      exit
    end

    puts "\n" + "=" * 60
    puts "COMPANY ANALYTICS SUMMARY".center(60)
    puts "=" * 60

    puts "\n📊 OVERVIEW"
    puts "  Total Employees:     #{analytics.total_employees}"
    puts "  Total Responses:     #{analytics.total_responses}"
    puts "  Response Rate:       #{analytics.response_rate}%"
    puts "  Engagement Level:    #{analytics.engagement_level.upcase}"

    puts "\n🎯 eNPS METRICS"
    puts "  eNPS Score:          #{analytics.enps_score}"
    puts "  eNPS Level:          #{analytics.enps_level.upcase}"
    puts "  Promoters:           #{analytics.promoters_count} (#{(analytics.promoters_count.to_f / analytics.total_responses * 100).round(1)}%)"
    puts "  Passives:            #{analytics.passives_count} (#{(analytics.passives_count.to_f / analytics.total_responses * 100).round(1)}%)"
    puts "  Detractors:          #{analytics.detractors_count} (#{(analytics.detractors_count.to_f / analytics.total_responses * 100).round(1)}%)"

    puts "\n💪 TOP 3 STRENGTHS"
    analytics.top_strengths.each_with_index do |(dimension, score), idx|
      puts "  #{idx + 1}. #{dimension.to_s.titleize}: #{score}%"
    end

    puts "\n⚠️  TOP 3 IMPROVEMENT AREAS"
    analytics.improvement_areas.each_with_index do |(dimension, score), idx|
      puts "  #{idx + 1}. #{dimension.to_s.titleize}: #{score}%"
    end

    puts "\n📈 FAVORABILITY BY DIMENSION"
    analytics.favorability_ranking.each do |dimension, score|
      bar = "█" * (score.to_f / 5).round
      puts "  #{dimension.to_s.titleize.ljust(35)} #{score.to_s.rjust(5)}% #{bar}"
    end

    puts "\n" + "=" * 60
    puts "Last calculated: #{analytics.calculated_at.strftime('%Y-%m-%d %H:%M:%S')}"
    puts "=" * 60 + "\n"
  end

  desc "Show department rankings"
  task departments: :environment do
    departments = DepartmentAnalytic.by_enps

    if departments.empty?
      puts "No department data available. Run 'rails analytics:refresh' first."
      exit
    end

    puts "\n" + "=" * 80
    puts "DEPARTMENT RANKINGS (by eNPS)".center(80)
    puts "=" * 80

    puts "\n%-30s %10s %10s %10s" % ["Department", "eNPS", "Employees", "Response Rate"]
    puts "-" * 80

    departments.each do |dept|
      puts "%-30s %10s %10s %10s%%" % [
        dept.department.to_s.titleize,
        dept.enps_score,
        dept.total_employees,
        dept.response_rate
      ]
    end

    puts "\n" + "=" * 80 + "\n"
  end

  desc "Identify at-risk departments (eNPS < 0)"
  task at_risk: :environment do
    at_risk_depts = DepartmentAnalytic.needs_attention

    puts "\n" + "=" * 80
    puts "⚠️  AT-RISK DEPARTMENTS (eNPS < 0)".center(80)
    puts "=" * 80

    if at_risk_depts.empty?
      puts "\n✓ No departments at risk! All departments have positive eNPS."
    else
      at_risk_depts.each do |dept|
        puts "\n📍 #{dept.department.to_s.upcase}"
        puts "  eNPS Score: #{dept.enps_score}"
        puts "  Detractors: #{dept.detractors_count} | Promoters: #{dept.promoters_count}"
        puts "\n  Areas for improvement:"
        dept.areas_for_improvement(60).each do |dimension, score|
          puts "    - #{dimension.to_s.titleize}: #{score}%"
        end
      end
    end

    puts "\n" + "=" * 80 + "\n"
  end
end
