class RenameErrorsColumnInCsvImports < ActiveRecord::Migration[8.1]
  def change
    rename_column :csv_imports, :errors, :import_errors
  end
end
