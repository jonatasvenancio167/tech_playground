class CreateEmployees < ActiveRecord::Migration[7.1]
  def change
    create_table :employees do |t|
      t.text :name, null: false
      t.citext :email
      t.citext :corporate_email
      t.text :mobile_phone
      t.text :department
      t.text :position
      t.text :function
      t.text :location
      t.integer :company_tenure_months
      t.text :gender
      t.text :generation
      t.text :n0_company
      t.text :n1_directorate
      t.text :n2_management
      t.text :n3_coordination
      t.text :n4_area
      t.timestamps
    end

    add_index :employees, :corporate_email, unique: true, where: "corporate_email IS NOT NULL"
    add_index :employees, :email
    add_index :employees, :department
    add_index :employees, :location
  end
end

