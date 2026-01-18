module DashboardsHelper
  def enps_class(score)
    case score.to_f
    when 70.. then "excellent"
    when 50...70 then "very_good"
    when 30...50 then "good"
    when 0...30 then "needs_improvement"
    else "critical"
    end
  end

  def enps_badge_color(level)
    case level.to_s
    when "excellent" then "success"
    when "very_good" then "info"
    when "good" then "primary"
    when "needs_improvement" then "warning"
    when "critical" then "danger"
    else "secondary"
    end
  end

  def favorability_color(percentage)
    case percentage.to_f
    when 80.. then "#10b981"
    when 60...80 then "#3b82f6"
    when 40...60 then "#f59e0b"
    else "#ef4444"
    end
  end

  def format_dimension_name(dimension)
    I18n.t("dimensions.#{dimension}", default: dimension.to_s.titleize.gsub("And", "and"))
  end

  def participation_level_badge(rate)
    case rate.to_f
    when 80.. then content_tag(:span, I18n.t('participation_levels.excellent'), class: "badge badge-success")
    when 60...80 then content_tag(:span, I18n.t('participation_levels.good'), class: "badge badge-info")
    when 40...60 then content_tag(:span, I18n.t('participation_levels.medium'), class: "badge badge-warning")
    else content_tag(:span, I18n.t('participation_levels.low'), class: "badge badge-danger")
    end
  end

  def enps_level_label(level)
    I18n.t("enps_levels.#{level}", default: level.to_s.titleize)
  end

  def trend_arrow(current, previous)
    return "" if previous.nil? || previous.zero?

    change = ((current - previous) / previous.abs * 100).round(1)

    if change > 0
      content_tag(:span, "↑ #{change}%", class: "trend-up")
    elsif change < 0
      content_tag(:span, "↓ #{change.abs}%", class: "trend-down")
    else
      content_tag(:span, "→ 0%", class: "trend-neutral")
    end
  end

  def chart_colors
    {
      promoters: "#10b981",
      passives: "#f59e0b",
      detractors: "#ef4444",
      primary: "#3b82f6",
      success: "#10b981",
      warning: "#f59e0b",
      danger: "#ef4444"
    }
  end
end
