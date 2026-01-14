module Api
  module V1
    class ResponsesController < BaseController
      def index
        scope = ResponsesQuery.new(params).call
        records, meta = PaginationService.paginate(scope, params)
        render json: { data: ResponseSerializer.render(records), meta: meta }
      end
    end
  end
end

