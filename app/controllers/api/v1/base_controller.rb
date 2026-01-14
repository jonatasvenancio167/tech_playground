module Api
  module V1
    class BaseController < ActionController::API
      private
      def paginate(scope)
        page = params.fetch(:page, 1).to_i
        per_page = params.fetch(:per_page, 25).to_i
        per_page = 100 if per_page > 100
        per_page = 1 if per_page < 1
        page = 1 if page < 1
        total = scope.count
        results = scope.limit(per_page).offset((page - 1) * per_page)
        [results, { page:, per_page:, total: }]
      end
    end
  end
end

