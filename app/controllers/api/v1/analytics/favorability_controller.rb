module Api
  module V1
    module Analytics
      class FavorabilityController < Api::V1::BaseController
        # GET /api/v1/analytics/favorability
        def index
          scope = build_scope
          service = ::Analytics::FavorabilityService.new(scope)

          render json: {
            data: {
              type: "favorability",
              attributes: {
                dimensions: service.calculate_all,
                overall: service.overall_favorability,
                ranking: service.ranking,
                top_strengths: service.top_strengths(3),
                improvement_areas: service.improvement_areas(3)
              },
              meta: {
                total_responses: scope.count,
                filters: filter_params
              }
            }
          }
        end

        # GET /api/v1/analytics/favorability/by_department
        def by_department
          if params[:department].present?
            service = ::Analytics::FavorabilityService.by_department(params[:department])

            render json: {
              data: {
                type: "favorability",
                attributes: {
                  department: params[:department],
                  dimensions: service.calculate_all,
                  overall: service.overall_favorability
                }
              }
            }
          else
            results = ::Analytics::FavorabilityService.by_department

            render json: {
              data: {
                type: "favorability_by_department",
                attributes: {
                  departments: results.transform_values { |v| {
                    dimensions: v,
                    overall: calculate_overall(v)
                  }}
                }
              }
            }
          end
        end

        # GET /api/v1/analytics/favorability/by_location
        def by_location
          if params[:location].present?
            service = ::Analytics::FavorabilityService.by_location(params[:location])

            render json: {
              data: {
                type: "favorability",
                attributes: {
                  location: params[:location],
                  dimensions: service.calculate_all,
                  overall: service.overall_favorability
                }
              }
            }
          else
            results = ::Analytics::FavorabilityService.by_location

            render json: {
              data: {
                type: "favorability_by_location",
                attributes: {
                  locations: results.transform_values { |v| {
                    dimensions: v,
                    overall: calculate_overall(v)
                  }}
                }
              }
            }
          end
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

        def calculate_overall(dimensions)
          percentages = dimensions.values.map { |v| v[:percentage] }
          return 0.0 if percentages.empty?

          (percentages.sum / percentages.size).round(2)
        end
      end
    end
  end
end
