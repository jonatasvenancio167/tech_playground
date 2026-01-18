require "csv"

class CsvImporterWithProgress
  Result = Struct.new(:employees_created, :responses_created, :errors, keyword_init: true)

  PROGRESS_UPDATE_INTERVAL = 50 

  def initialize(io:, csv_import:)
    @io = io
    @csv_import = csv_import
  end

  def import
    employees_created = 0
    responses_created = 0
    errors = []
    processed = 0

    csv = CSV.new(@io, headers: true, col_sep: ";")

    csv.each.with_index do |row, index|
      processed += 1

      begin
        ActiveRecord::Base.transaction do
          employee = find_or_create_employee(row)
          newly = employee.previously_new_record?
          employees_created += 1 if newly

          create_response(employee, row)
          responses_created += 1
        end
      rescue => e
        errors << build_error_message(row, index + 2, e)
      end

      update_progress(processed) if should_update_progress?(processed)
    end

    update_progress(processed)

    Result.new(
      employees_created: employees_created,
      responses_created: responses_created,
      errors: errors
    )
  end

  private

  def should_update_progress?(processed)
    processed % PROGRESS_UPDATE_INTERVAL == 0
  end

  def update_progress(processed)
    @csv_import.update_progress!(processed_rows: processed)
  rescue => e
    Rails.logger.warn "[CsvImporterWithProgress] Failed to update progress: #{e.message}"
  end

  def find_or_create_employee(row)
    employee = Employee.find_or_initialize_by(
      corporate_email: safe(row["email_corporativo"])
    )

    employee.assign_attributes(
      name: safe(row["nome"]) || employee.name,
      email: safe(row["email"]),
      mobile_phone: safe(row["celular"]),
      department: safe(row["area"]),
      position: safe(row["cargo"]),
      function: safe(row["funcao"]),
      location: safe(row["localidade"]),
      company_tenure_months: parse_int(row["tempo_de_empresa"]),
      gender: safe(row["genero"]),
      generation: safe(row["geracao"]),
      n0_company: safe(row["n0_empresa"]),
      n1_directorate: safe(row["n1_diretoria"]),
      n2_management: safe(row["n2_gerencia"]),
      n3_coordination: safe(row["n3_coordenacao"]),
      n4_area: safe(row["n4_area"])
    )

    employee.save!
    employee
  end

  def safe(v)
    s = v.to_s.strip
    s.empty? ? nil : s
  end

  def parse_int(v)
    s = safe(v)
    return nil if s.nil?
    Integer(s) rescue nil
  end

  def parse_date(v)
    s = safe(v)
    return Date.today if s.nil?
    Date.parse(s) rescue Date.today
  end

  def create_response(employee, row)
    response = employee.responses.build(
      response_date: parse_date(row["Data da Resposta"]),
      interest_in_position: parse_int(row["Interesse no Cargo"]),
      interest_in_position_comment: safe(row["Comentários - Interesse no Cargo"]),
      contribution: parse_int(row["Contribuição"]),
      contribution_comment: safe(row["Comentários - Contribuição"]),
      learning_and_development: parse_int(row["Aprendizado e Desenvolvimento"]),
      learning_and_development_comment: safe(row["Comentários - Aprendizado e Desenvolvimento"]),
      feedback: parse_int(row["Feedback"]),
      feedback_comment: safe(row["Comentários - Feedback"]),
      interaction_with_manager: parse_int(row["Interação com Gestor"]),
      interaction_with_manager_comment: safe(row["Comentários - Interação com Gestor"]),
      career_opportunity_clarity: parse_int(row["Clareza sobre Possibilidades de Carreira"]),
      career_opportunity_clarity_comment: safe(row["Comentários - Clareza sobre Possibilidades de Carreira"]),
      permanence_expectation: parse_int(row["Expectativa de Permanência"]),
      permanence_expectation_comment: safe(row["Comentários - Expectativa de Permanência"]),
      enps: parse_int(row["eNPS"]),
      enps_open_comment: safe(row["[Aberta] eNPS"])
    )

    response.save!
    response
  end

  def build_error_message(row, line_number, error)
    {
      line: line_number,
      employee: row["nome"],
      error: error.message
    }
  end
end
