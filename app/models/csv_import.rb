class CsvImport < ApplicationRecord
  # Status constants
  STATUSES = %w[pending processing completed failed].freeze

  # Validations
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :file_path, presence: true

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :processing, -> { where(status: 'processing') }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :recent, -> { order(created_at: :desc) }

  def pending?
    status == 'pending'
  end

  def processing?
    status == 'processing'
  end

  def completed?
    status == 'completed'
  end

  def failed?
    status == 'failed'
  end

  def start_processing!
    update!(
      status: 'processing',
      started_at: Time.current
    )
  end

  def complete!(employees_created:, responses_created:, import_errors: [])
    update!(
      status: 'completed',
      employees_created: employees_created,
      responses_created: responses_created,
      import_errors: import_errors,
      completed_at: Time.current
    )
  end

  def fail!(error_message)
    update!(
      status: 'failed',
      error_message: error_message,
      completed_at: Time.current
    )
  end

  def update_progress!(processed_rows:, total_rows: nil)
    attrs = { processed_rows: processed_rows }
    attrs[:total_rows] = total_rows if total_rows
    update!(attrs)
  end

  def progress_percentage
    return 0 if total_rows.zero?
    ((processed_rows.to_f / total_rows) * 100).round(1)
  end

  def duration
    return nil unless started_at
    end_time = completed_at || Time.current
    end_time - started_at
  end

  def duration_in_words
    seconds = duration
    return nil unless seconds

    if seconds < 60
      I18n.t('csv_imports.duration.seconds', count: seconds.round)
    elsif seconds < 3600
      I18n.t('csv_imports.duration.minutes', count: (seconds / 60).round)
    else
      I18n.t('csv_imports.duration.hours', count: (seconds / 3600).round(1))
    end
  end

  def has_import_errors?
    import_errors.present? && import_errors.any?
  end

  def status_label
    I18n.t("csv_imports.statuses.#{status}")
  end
end
