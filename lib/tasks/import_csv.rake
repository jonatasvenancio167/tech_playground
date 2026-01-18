namespace :data do
  desc "Importa dados do arquivo data.csv para PostgreSQL"
  task import: :environment do
    require "csv"

    path = Rails.root.join("./", "data.csv")

    unless File.exist?(path)
      abort("Arquivo CSV não encontrado em #{path}")
    end

    puts "Iniciando importação de #{path}..."
    start_time = Time.current

    File.open(path, "r") do |file|
      result = CsvImporter.new(io: file).import
      
      elapsed = (Time.current - start_time).round(2)
      
      puts "\n" + "="*60
      puts "IMPORTAÇÃO CONCLUÍDA em #{elapsed}s"
      puts "="*60
      puts "Funcionários criados: #{result.employees_created}"
      puts "Respostas criadas:    #{result.responses_created}"
      puts "Erros:                #{result.errors.size}"
      
      if result.errors.any?
        puts "\n ERROS ENCONTRADOS:"
        result.errors.first(10).each_with_index do |error, i|
          puts "   #{i+1}. #{error}"
        end
        puts "   ... e mais #{result.errors.size - 10} erros" if result.errors.size > 10
      end
      puts "="*60
    end
  end
end
