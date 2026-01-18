class CreateCsvImports < ActiveRecord::Migration[8.1]
  def change
    create_table :csv_imports do |t|
      t.string :status, null: false, default: 'pending'
      t.string :file_name
      t.string :file_path
      t.integer :total_rows, default: 0
      t.integer :processed_rows, default: 0
      t.integer :employees_created, default: 0
      t.integer :responses_created, default: 0
      t.jsonb :errors, default: []
      t.text :error_message
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :csv_imports, :status
    add_index :csv_imports, :created_at
  end
end
