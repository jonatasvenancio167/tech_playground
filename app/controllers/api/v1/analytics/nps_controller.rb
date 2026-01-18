module Api
  module V1
    module Analytics
      class NpsController < Api::V1::BaseController
        # GET /api/v1/analytics/nps
        def index
          scope = build_scope
          service = ::Analytics::NpsService.new(scope)

          render json: {
            data: {
              type: "nps",
              attributes: service.calculate,
              meta: {
                filters: filter_params
              }
            }
          }
        end

        # GET /api/v1/analytics/nps/distribution
        def distribution
          scope = build_scope
          service = ::Analytics::NpsService.new(scope)

          render json: {
            data: {
              type: "nps_distribution",
              attributes: {
                distribution: service.distribution,
                summary: service.calculate
              }
            }
          }
        end

        # GET /api/v1/analytics/nps/trend
        def trend
          scope = build_scope
          service = ::Analytics::NpsService.new(scope)

          period = params[:period]&.to_sym || :month
          limit = params[:limit]&.to_i || 12

          render json: {
            data: {
              type: "nps_trend",
              attributes: {
                trend: service.trend(period: period, limit: limit),
                current: service.calculate
              },
              meta: {
                period: period,
                limit: limit
              }
            }
          }
        end

        # GET /api/v1/analytics/nps/by_department
        def by_department
          if params[:department].present?
            service = ::Analytics::NpsService.by_department(params[:department])

            render json: {
              data: {
                type: "nps",
                attributes: {
                  department: params[:department],
                  **service.calculate
                }
              }
            }
          else
            results = ::Analytics::NpsService.by_department

            render json: {
              data: {
                type: "nps_by_department",
                attributes: {
                  departments: results
                }
              }
            }
          end
        end

        # GET /api/v1/analytics/nps/by_location
        def by_location
          if params[:location].present?
            service = ::Analytics::NpsService.by_location(params[:location])

            render json: {
              data: {
                type: "nps",
                attributes: {
                  location: params[:location],
                  **service.calculate
                }
              }
            }
          else
            results = ::Analytics::NpsService.by_location

            render json: {
              data: {
                type: "nps_by_location",
                attributes: {
                  locations: results
                }
              }
            }
          end
        end

        # GET /api/v1/analytics/nps/at_risk
        def at_risk
          render json: {
            data: {
              type: "at_risk_departments",
              attributes: {
                departments: ::Analytics::NpsService.at_risk_departments
              }
            }
          }
        end

        private

        def build_scope
          scope = Response.all

          if params[:department].present?
            scope = scope.joins(:employee).where(employees: { department: params[:department] })
          end

          if params[:location].present?
            scope = scope.joins(:employee).where(employees: { location: params[:location] })
          end

          if params[:date_from].present?
            scope = scope.where("response_date >= ?", params[:date_from])
          end

          if params[:date_to].present?
            scope = scope.where("response_date <= ?", params[:date_to])
          end

          scope
        end

        def filter_params
          params.permit(:department, :location, :date_from, :date_to).to_h
        end
      end
    end
  end
end
