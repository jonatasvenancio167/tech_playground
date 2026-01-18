class ReportsController < ApplicationController
  before_action :set_filters

  def index; end

  def generate
    report_type = params[:report_type] || 'pdf'
    report_class = report_type == 'pdf' ? Reports::PdfReport : Reports::ExcelReport

    begin
      report = report_class.new(@filters)
      report.generate

      send_data report.data,
                filename: report.filename,
                type: report_type == 'pdf' ? 'application/pdf' : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                disposition: 'attachment'
    rescue => e
      redirect_to reports_path, alert: t('reports.error_generating', message: e.message)
    end
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
end
