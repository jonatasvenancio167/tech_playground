module Api
  module V1
    module Analytics
      class DashboardController < Api::V1::BaseController
        # GET /api/v1/analytics/dashboard
        def index
          service = ::Analytics::DashboardService.new(filter_params)

          render json: {
            data: {
              type: "dashboard",
              attributes: service.company_overview
            }
          }
        end

        # GET /api/v1/analytics/dashboard/executive
        def executive
          service = ::Analytics::DashboardService.new(filter_params)

          render json: {
            data: {
              type: "executive_summary",
              attributes: service.executive_summary
            }
          }
        end

        # GET /api/v1/analytics/dashboard/departments
        def departments
          service = ::Analytics::DashboardService.new(filter_params)

          render json: {
            data: {
              type: "department_breakdown",
              attributes: {
                departments: service.department_breakdown
              }
            }
          }
        end

        # GET /api/v1/analytics/dashboard/trends
        def trends
          months = params[:months]&.to_i || 6
          service = ::Analytics::DashboardService.new(filter_params)

          render json: {
            data: {
              type: "trends",
              attributes: service.trends(months: months)
            }
          }
        end

        # GET /api/v1/analytics/dashboard/alerts
        def alerts
          service = ::Analytics::DashboardService.new(filter_params)

          render json: {
            data: {
              type: "attention_areas",
              attributes: service.attention_areas
            }
          }
        end

        private

        def filter_params
          params.permit(:department, :location, :date_from, :date_to).to_h.symbolize_keys
        end
      end
    end
  end
end
