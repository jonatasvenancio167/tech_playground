require "csv"

class CsvImporter
  Result = Struct.new(:employees_created, :responses_created, :errors, keyword_init: true)

  def initialize(io:)
    @io = io
  end

  def import
    employees_created = 0
    responses_created = 0
    errors = []

    CSV.new(@io, headers: true, col_sep: ";").each do |row|
      ActiveRecord::Base.transaction do
        employee = Employee.find_or_initialize_by(corporate_email: safe(row["email_corporativo"]))
        employee.name = safe(row["nome"]) || employee.name
        employee.email = safe(row["email"])
        employee.mobile_phone = safe(row["celular"])
        employee.department = safe(row["area"])
        employee.position = safe(row["cargo"])
        employee.function = safe(row["funcao"])
        employee.location = safe(row["localidade"])
        employee.company_tenure_months = parse_int(row["tempo_de_empresa"])
        employee.gender = safe(row["genero"])
        employee.generation = safe(row["geracao"])
        employee.n0_company = safe(row["n0_empresa"])
        employee.n1_directorate = safe(row["n1_diretoria"])
        employee.n2_management = safe(row["n2_gerencia"])
        employee.n3_coordination = safe(row["n3_coordenacao"])
        employee.n4_area = safe(row["n4_area"])
        newly = employee.new_record?
        employee.save!
        employees_created += 1 if newly

        Response.create!(
          employee: employee,
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
        responses_created += 1
      rescue => e
        errors << e.message
      end
    end

    Result.new(employees_created: employees_created, responses_created: responses_created, errors: errors)
  end

  private

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
end

