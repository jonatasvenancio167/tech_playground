class Employee < ApplicationRecord
  has_many :responses, dependent: :destroy

  validates :name, :email, presence: true
  validates :email, uniqueness: true, 
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :corporate_email, 
            format: { with: URI::MailTo::EMAIL_REGEXP }, 
            allow_blank: true

  before_validation :normalize_department
  
  # Scopes
  scope :by_department, ->(dept) { where(department: dept) }
  scope :by_location, ->(loc) { where(location: loc) }
  scope :by_generation, ->(gen) { where(generation: gen) }
  scope :with_responses, -> { joins(:responses).distinct }
  scope :without_responses, -> {
    left_joins(:responses)
      .where(responses: { id: nil })
  }

  # Métodos de instância
  def response_rate
    return 0 if responses.empty?
    100.0
  end

  def average_score(field)
    responses.average(field)&.round(2)
  end

  def latest_response
    responses.order(response_date: :desc).first
  end

  def enps_category
    latest_response&.enps_category
  end

  # Estatísticas agregadas do funcionário
  def overall_favorability
    return 0 if responses.empty?
    responses.average(:favorability_percentage)&.round(2) || 0
  end

  def average_enps
    responses.average(:enps)&.round(2)
  end
  
  private
  
  def normalize_department
    self.department = department&.downcase&.strip
  end
end

