class DashboardsController < ApplicationController
  before_action :set_filters

  def index
    @service = Analytics::DashboardService.new(@filters)
    @overview = @service.company_overview
    @executive = @service.executive_summary
  end

  def company
    @service = Analytics::DashboardService.new(@filters)
    @overview = @service.company_overview
    @nps_service = Analytics::NpsService.new(build_scope)
    @fav_service = Analytics::FavorabilityService.new(build_scope)
  end

  def departments
    @service = Analytics::DashboardService.new(@filters)
    @departments = @service.department_breakdown
  end

  def trends
    @months = params[:months]&.to_i || 6
    @service = Analytics::DashboardService.new(@filters)
    @trends = @service.trends(months: @months)
  end

  def employee
    @employee = Employee.find(params[:id])
    @responses = @employee.responses.order(response_date: :desc)
    @latest = @responses.first
  end

  private

  def set_filters
    @filters = {
      department: params[:department],
      location: params[:location],
      date_from: params[:date_from],
      date_to: params[:date_to]
    }.compact.symbolize_keys
  end

  def build_scope
    scope = Response.all
    scope = scope.joins(:employee).where(employees: { department: @filters[:department] }) if @filters[:department]
    scope = scope.joins(:employee).where(employees: { location: @filters[:location] }) if @filters[:location]
    scope = scope.where("response_date >= ?", @filters[:date_from]) if @filters[:date_from]
    scope = scope.where("response_date <= ?", @filters[:date_to]) if @filters[:date_to]
    scope
  end
end
