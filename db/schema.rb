# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_14_000700) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"

  create_table "csv_imports", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "employees_created", default: 0
    t.text "error_message"
    t.string "file_name"
    t.string "file_path"
    t.jsonb "import_errors", default: []
    t.integer "processed_rows", default: 0
    t.integer "responses_created", default: 0
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.integer "total_rows", default: 0
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_csv_imports_on_created_at"
    t.index ["status"], name: "index_csv_imports_on_status"
  end

  create_table "employees", force: :cascade do |t|
    t.integer "company_tenure_months"
    t.citext "corporate_email"
    t.datetime "created_at", null: false
    t.text "department"
    t.citext "email"
    t.text "function"
    t.text "gender"
    t.text "generation"
    t.text "location"
    t.text "mobile_phone"
    t.text "n0_company"
    t.text "n1_directorate"
    t.text "n2_management"
    t.text "n3_coordination"
    t.text "n4_area"
    t.text "name", null: false
    t.text "position"
    t.datetime "updated_at", null: false
    t.index ["corporate_email"], name: "index_employees_on_corporate_email", unique: true, where: "(corporate_email IS NOT NULL)"
    t.index ["department"], name: "index_employees_on_department"
    t.index ["email"], name: "index_employees_on_email"
    t.index ["location"], name: "index_employees_on_location"
  end

  create_table "responses", force: :cascade do |t|
    t.integer "career_opportunity_clarity"
    t.text "career_opportunity_clarity_comment"
    t.integer "contribution"
    t.text "contribution_comment"
    t.datetime "created_at", null: false
    t.bigint "employee_id", null: false
    t.integer "enps"
    t.text "enps_open_comment"
    t.integer "feedback"
    t.text "feedback_comment"
    t.integer "interaction_with_manager"
    t.text "interaction_with_manager_comment"
    t.integer "interest_in_position"
    t.text "interest_in_position_comment"
    t.integer "learning_and_development"
    t.text "learning_and_development_comment"
    t.integer "permanence_expectation"
    t.text "permanence_expectation_comment"
    t.date "response_date", null: false
    t.datetime "updated_at", null: false
    t.index ["contribution"], name: "index_responses_on_contribution"
    t.index ["employee_id", "enps"], name: "index_responses_on_employee_enps"
    t.index ["employee_id", "response_date"], name: "index_responses_on_employee_id_and_response_date"
    t.index ["employee_id"], name: "index_responses_on_employee_id"
    t.index ["interest_in_position"], name: "index_responses_on_interest"
    t.index ["learning_and_development"], name: "index_responses_on_learning"
    t.index ["response_date", "enps"], name: "index_responses_on_date_enps"
    t.index ["response_date"], name: "index_responses_on_response_date"
    t.check_constraint "career_opportunity_clarity IS NULL OR career_opportunity_clarity >= 1 AND career_opportunity_clarity <= 7", name: "career_opportunity_clarity_range"
    t.check_constraint "contribution IS NULL OR contribution >= 1 AND contribution <= 7", name: "contribution_range"
    t.check_constraint "enps IS NULL OR enps >= 0 AND enps <= 10", name: "enps_range"
    t.check_constraint "feedback IS NULL OR feedback >= 1 AND feedback <= 7", name: "feedback_range"
    t.check_constraint "interaction_with_manager IS NULL OR interaction_with_manager >= 1 AND interaction_with_manager <= 7", name: "interaction_with_manager_range"
    t.check_constraint "interest_in_position IS NULL OR interest_in_position >= 1 AND interest_in_position <= 7", name: "interest_in_position_range"
    t.check_constraint "learning_and_development IS NULL OR learning_and_development >= 1 AND learning_and_development <= 7", name: "learning_and_development_range"
    t.check_constraint "permanence_expectation IS NULL OR permanence_expectation >= 1 AND permanence_expectation <= 7", name: "permanence_expectation_range"
  end

  add_foreign_key "responses", "employees"
end
