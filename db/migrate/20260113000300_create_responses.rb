class CreateResponses < ActiveRecord::Migration[7.1]
  def change
    create_table :responses do |t|
      t.references :employee, null: false, foreign_key: true
      t.date :response_date, null: false
      t.integer :interest_in_position
      t.text :interest_in_position_comment
      t.integer :contribution
      t.text :contribution_comment
      t.integer :learning_and_development
      t.text :learning_and_development_comment
      t.integer :feedback
      t.text :feedback_comment
      t.integer :interaction_with_manager
      t.text :interaction_with_manager_comment
      t.integer :career_opportunity_clarity
      t.text :career_opportunity_clarity_comment
      t.integer :permanence_expectation
      t.text :permanence_expectation_comment
      t.integer :enps
      t.text :enps_open_comment
      t.timestamps
    end

    add_index :responses, :response_date
    add_index :responses, [:employee_id, :response_date]
  end
end

