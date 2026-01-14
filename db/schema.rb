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

ActiveRecord::Schema[8.1].define(version: 2026_01_13_000300) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"

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
    t.index ["employee_id", "response_date"], name: "index_responses_on_employee_id_and_response_date"
    t.index ["employee_id"], name: "index_responses_on_employee_id"
    t.index ["response_date"], name: "index_responses_on_response_date"
  end

  add_foreign_key "responses", "employees"
end
