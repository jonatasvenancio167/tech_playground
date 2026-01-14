module Api
  module V1
    class ImportsController < BaseController
      require Rails.root.join("app/services/csv_importer")
      def create
        uploaded = params[:file]
        unless uploaded.respond_to?(:tempfile)
          render json: { error: "Arquivo CSV é obrigatório (campo: file)" }, status: :bad_request and return
        end
        result = ::CsvImporter.new(io: uploaded.tempfile).import
        status = result.errors.any? ? :multi_status : :created
        render json: {
          employees_created: result.employees_created,
          responses_created: result.responses_created,
          errors: result.errors
        }, status: status
      end
    end
  end
end
