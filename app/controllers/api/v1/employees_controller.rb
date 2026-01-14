module Api
  module V1
    class EmployeesController < BaseController
      def index
        scope = Employee.all
        scope = scope.where(department: params[:department]) if params[:department].present?
        scope = scope.where(location: params[:location]) if params[:location].present?
        if params[:q].present?
          q = "%#{params[:q]}%"
          scope = scope.where("name ILIKE ? OR email ILIKE ? OR corporate_email ILIKE ?", q, q, q)
        end
        records, meta = paginate(scope.order(id: :asc))
        render json: {
          data: records.as_json(only: [:id, :name, :email, :corporate_email, :department, :position, :function, :location]),
          meta:
        }
      end

      def show
        e = Employee.find(params[:id])
        render json: e.as_json(
          only: [:id, :name, :email, :corporate_email, :mobile_phone, :department, :position, :function, :location,
                 :company_tenure_months, :gender, :generation, :n0_company, :n1_directorate, :n2_management,
                 :n3_coordination, :n4_area]
        )
      end
    end
  end
end

