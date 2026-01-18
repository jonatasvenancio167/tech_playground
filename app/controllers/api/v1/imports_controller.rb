module Api
  module V1
    class ImportsController < BaseController
      # POST /api/v1/imports
      # Enqueue a CSV file for async processing
      def create
        uploaded = params[:file]

        unless uploaded.respond_to?(:tempfile)
          render json: { error: I18n.t('api.errors.csv_required') }, status: :bad_request
          return
        end

        # Save the file to a permanent location
        file_path = save_uploaded_file(uploaded)

        # Create import record and enqueue job
        csv_import = CsvImport.create!(
          file_name: uploaded.original_filename,
          file_path: file_path,
          status: 'pending'
        )

        # Enqueue the job
        CsvImportJob.perform_later(csv_import.id)

        render json: {
          id: csv_import.id,
          status: csv_import.status,
          message: I18n.t('csv_imports.messages.queued'),
          status_url: api_v1_import_path(csv_import)
        }, status: :accepted
      end

      # GET /api/v1/imports/:id
      # Check the status of an import
      def show
        csv_import = CsvImport.find(params[:id])

        render json: {
          id: csv_import.id,
          status: csv_import.status,
          status_label: csv_import.status_label,
          file_name: csv_import.file_name,
          progress: {
            total_rows: csv_import.total_rows,
            processed_rows: csv_import.processed_rows,
            percentage: csv_import.progress_percentage
          },
          results: {
            employees_created: csv_import.employees_created,
            responses_created: csv_import.responses_created,
            errors: csv_import.import_errors
          },
          error_message: csv_import.error_message,
          started_at: csv_import.started_at,
          completed_at: csv_import.completed_at,
          duration: csv_import.duration_in_words
        }
      end

      # GET /api/v1/imports
      # List recent imports
      def index
        imports = CsvImport.recent.limit(20)

        render json: imports.map { |csv_import|
          {
            id: csv_import.id,
            status: csv_import.status,
            status_label: csv_import.status_label,
            file_name: csv_import.file_name,
            progress_percentage: csv_import.progress_percentage,
            employees_created: csv_import.employees_created,
            responses_created: csv_import.responses_created,
            has_errors: csv_import.has_import_errors?,
            created_at: csv_import.created_at,
            completed_at: csv_import.completed_at
          }
        }
      end

      private

      def save_uploaded_file(uploaded)
        # Create uploads directory if it doesn't exist
        uploads_dir = Rails.root.join('tmp', 'uploads', 'csv_imports')
        FileUtils.mkdir_p(uploads_dir)

        # Generate unique filename
        timestamp = Time.current.strftime('%Y%m%d%H%M%S')
        random_suffix = SecureRandom.hex(4)
        original_name = File.basename(uploaded.original_filename, '.*')
        extension = File.extname(uploaded.original_filename)
        filename = "#{original_name}_#{timestamp}_#{random_suffix}#{extension}"

        file_path = uploads_dir.join(filename).to_s

        # Copy the file
        FileUtils.cp(uploaded.tempfile.path, file_path)

        file_path
      end
    end
  end
end
