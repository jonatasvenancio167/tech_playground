class LocationAnalytic < ApplicationRecord
  self.table_name = "location_analytics"
  self.primary_key = :location

  # Scopes
  scope :by_enps, -> { order(enps_score: :desc) }
  scope :with_high_engagement, -> { where("response_rate > ?", 70) }
  scope :needs_attention, -> { where("enps_score < ?", 0) }

  def readonly?
    true
  end

  def self.refresh!
    connection.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY location_analytics")
  end
end
