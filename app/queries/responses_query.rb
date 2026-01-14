class ResponsesQuery
  def initialize(params)
    @params = params
  end

  def call
    scope = Response.includes(:employee).references(:employee)
    scope = scope.where(employee_id: employee_id) if employee_id
    scope = scope.where("response_date >= ?", date_from) if date_from
    scope = scope.where("response_date <= ?", date_to) if date_to
    scope = scope.where(employees: { department: department }) if department
    scope.order(response_date: :desc)
  end

  private

  def employee_id
    v = @params[:employee_id]
    return nil if v.nil? || v.to_s.strip.empty?
    v.to_i
  end

  def date_from
    parse_date(@params[:date_from])
  end

  def date_to
    parse_date(@params[:date_to])
  end

  def department
    s = @params[:department].to_s.strip
    s.empty? ? nil : s
  end

  def parse_date(v)
    s = v.to_s.strip
    return nil if s.empty?
    Date.parse(s) rescue nil
  end
end

