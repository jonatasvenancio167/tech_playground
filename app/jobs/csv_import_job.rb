class CsvImportJob < ApplicationJob
  queue_as :default

  # Retry on transient errors
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3
  retry_on ActiveRecord::ConnectionNotEstablished, wait: 5.seconds, attempts: 3

  # Discard if the import record no longer exists
  discard_on ActiveJob::DeserializationError

  def perform(csv_import_id)
    csv_import = CsvImport.find(csv_import_id)

    return if csv_import.processing? || csv_import.completed?

    csv_import.start_processing!

    begin
      result = process_csv(csv_import)

      csv_import.complete!(
        employees_created: result.employees_created,
        responses_created: result.responses_created,
        import_errors: result.errors
      )

      Rails.logger.info "[CsvImportJob] Import ##{csv_import_id} completed: #{result.employees_created} employees, #{result.responses_created} responses"
    rescue => e
      csv_import.fail!(e.message)
      Rails.logger.error "[CsvImportJob] Import ##{csv_import_id} failed: #{e.message}"
      raise e
    ensure
      cleanup_file(csv_import.file_path)
    end
  end

  private

  def process_csv(csv_import)
    file_path = csv_import.file_path

    unless File.exist?(file_path)
      raise I18n.t('csv_imports.errors.file_not_found')
    end

    # Count total rows first (for progress tracking)
    total_rows = count_csv_rows(file_path)
    csv_import.update_progress!(processed_rows: 0, total_rows: total_rows)

    # Process the CSV with progress updates
    File.open(file_path, 'r') do |file|
      importer = CsvImporterWithProgress.new(
        io: file,
        csv_import: csv_import
      )
      importer.import
    end
  end

  def count_csv_rows(file_path)
    count = 0
    File.foreach(file_path) { count += 1 }
    count - 1 # Subtract header row
  end

  def cleanup_file(file_path)
    return unless file_path && File.exist?(file_path)

    File.delete(file_path)
    Rails.logger.info "[CsvImportJob] Cleaned up file: #{file_path}"
  rescue => e
    Rails.logger.warn "[CsvImportJob] Failed to cleanup file #{file_path}: #{e.message}"
  end
end
