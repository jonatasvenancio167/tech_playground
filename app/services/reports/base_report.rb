module Reports
  class BaseReport
    attr_reader :data, :filters

    def initialize(filters = {})
      @filters = filters
      @data = nil
    end

    def generate
      raise NotImplementedError, "Subclasses must implement #generate"
    end

    def format
      :pdf
    end

    def filename
      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
      "#{report_name}_#{timestamp}.#{format}"
    end

    def metadata
      {
        report_type: report_name,
        generated_at: Time.current,
        filters_applied: @filters,
        generated_by: "Tech Playground Analytics System"
      }
    end

    protected

    def report_name
      self.class.name.demodulize.underscore
    end

    def apply_filters(scope)
      scope = scope.where("response_date >= ?", @filters[:date_from]) if @filters[:date_from]
      scope = scope.where("response_date <= ?", @filters[:date_to]) if @filters[:date_to]

      if @filters[:department]
        scope = scope.joins(:employee).where(employees: { department: @filters[:department] })
      end

      if @filters[:location]
        scope = scope.joins(:employee).where(employees: { location: @filters[:location] })
      end

      scope
    end
  end
end
