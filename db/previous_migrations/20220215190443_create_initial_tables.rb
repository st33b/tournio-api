class CreateInitialTables < ActiveRecord::Migration[7.0]
  def change
    create_table "additional_question_responses", force: :cascade do |t|
      t.bigint "bowler_id"
      t.bigint "extended_form_field_id"
      t.string "response", default: ""

      t.timestamps

      t.index ["bowler_id"], name: "index_additional_question_responses_on_bowler_id"
      t.index ["extended_form_field_id"], name: "index_additional_question_responses_on_extended_form_field_id"
    end

    create_table "additional_questions", force: :cascade do |t|
      t.bigint "tournament_id"
      t.bigint "extended_form_field_id"
      t.jsonb "validation_rules"
      t.integer "order"

      t.timestamps

      t.index ["extended_form_field_id"], name: "index_additional_questions_on_extended_form_field_id"
      t.index ["tournament_id"], name: "index_additional_questions_on_tournament_id"
    end

    create_table "bowlers", force: :cascade do |t|
      t.bigint "person_id"
      t.bigint "team_id"
      t.bigint "tournament_id"
      t.integer "position"
      t.bigint "doubles_partner_id"
      t.string "identifier"

      t.timestamps

      t.index ["doubles_partner_id"], name: "index_bowlers_on_doubles_partner_id"
      t.index ["identifier"], name: "index_bowlers_on_identifier"
      t.index ["person_id"], name: "index_bowlers_on_person_id"
      t.index ["team_id"], name: "index_bowlers_on_team_id"
      t.index ["tournament_id"], name: "index_bowlers_on_tournament_id"
    end

    create_table "config_items", force: :cascade do |t|
      t.string "key", null: false
      t.string "value", null: false
      t.bigint "tournament_id"

      t.timestamps

      t.index ["tournament_id", "key"], name: "index_config_items_on_tournament_id_and_key", unique: true
    end

    create_table "contacts", force: :cascade do |t|
      t.bigint "tournament_id"
      t.string "name"
      t.string "email"
      t.string "phone"
      t.text "notes"
      t.boolean "notify_on_registration", default: false
      t.boolean "notify_on_payment", default: false
      t.integer "role"

      t.timestamps

      t.index ["tournament_id"], name: "index_contacts_on_tournament_id"
    end

    create_table "extended_form_fields", force: :cascade do |t|
      t.string "name", null: false
      t.string "label", null: false
      t.string "html_element_type", default: "input"
      t.jsonb "html_element_config", default: {"type"=>"text", "value"=>""}
      t.jsonb "validation_rules", default: {"required"=>false}
      t.string "helper_text"
      t.string "helper_url"

      t.timestamps
    end

    create_table "free_entries", force: :cascade do |t|
      t.bigint "tournament_id", null: false
      t.string "unique_code"
      t.bigint "bowler_id"
      t.boolean "confirmed", default: false

      t.timestamps

      t.index ["bowler_id"], name: "index_free_entries_on_bowler_id"
      t.index ["tournament_id"], name: "index_free_entries_on_tournament_id"
    end

    create_table "ledger_entries", force: :cascade do |t|
      t.bigint "bowler_id", null: false
      t.decimal "debit", default: "0.0"
      t.decimal "credit", default: "0.0"
      t.integer "source", default: 0, null: false
      t.string "identifier"
      t.string "notes"

      t.timestamps

      t.index ["bowler_id"], name: "index_ledger_entries_on_bowler_id"
      t.index ["identifier"], name: "index_ledger_entries_on_identifier"
    end

    create_table "paypal_orders", force: :cascade do |t|
      t.string "identifier"
      t.jsonb "details"

      t.timestamps
    end

    create_table "people", force: :cascade do |t|
      t.string "first_name", null: false
      t.string "last_name", null: false
      t.string "email", null: false
      t.integer "birth_month", null: false
      t.integer "birth_day", null: false
      t.string "nickname"
      t.string "address1", null: false
      t.string "address2"
      t.string "city", null: false
      t.string "state", null: false
      t.string "postal_code", null: false
      t.string "country", null: false
      t.string "phone", null: false
      t.string "igbo_id"
      t.string "usbc_id"

      t.timestamps

      t.index ["last_name"], name: "index_people_on_last_name"
      t.index ["usbc_id"], name: "index_people_on_usbc_id"
    end

    create_table "purchasable_items", force: :cascade do |t|
      t.string "identifier", null: false
      t.string "category", null: false
      t.string "determination", null: false
      t.string "refinement"
      t.string "name", null: false
      t.boolean "user_selectable", default: true, null: false
      t.integer "value", default: 0, null: false
      t.jsonb "configuration", default: {}
      t.bigint "tournament_id"

      t.timestamps

      t.index ["tournament_id"], name: "index_purchasable_items_on_tournament_id"
    end

    create_table "purchases", force: :cascade do |t|
      t.string "identifier", null: false
      t.bigint "bowler_id"
      t.bigint "purchasable_item_id"
      t.integer "amount", default: 0
      t.datetime "paid_at"
      t.bigint "paypal_order_id"

      t.timestamps

      t.index ["bowler_id"], name: "index_purchases_on_bowler_id"
      t.index ["identifier"], name: "index_purchases_on_identifier"
      t.index ["paypal_order_id"], name: "index_purchases_on_paypal_order_id"
      t.index ["purchasable_item_id"], name: "index_purchases_on_purchasable_item_id"
    end

    create_table "teams", force: :cascade do |t|
      t.bigint "tournament_id"
      t.string "identifier", null: false
      t.string "name"

      t.timestamps

      t.index ["identifier"], name: "index_teams_on_identifier", unique: true
      t.index ["tournament_id"], name: "index_teams_on_tournament_id"
    end

    create_table "testing_environments", force: :cascade do |t|
      t.bigint "tournament_id", null: false
      t.jsonb "conditions", default: {"registration_period"=>"regular"}

      t.timestamps

      t.index ["tournament_id"], name: "index_testing_environments_on_tournament_id"
    end

    create_table "tournaments", force: :cascade do |t|
      t.string "name", null: false
      t.integer "year", null: false
      t.string "identifier", null: false
      t.string "aasm_state", null: false
      t.date "start_date"

      t.timestamps

      t.index ["aasm_state"], name: "index_tournaments_on_aasm_state"
      t.index ["identifier"], name: "index_tournaments_on_identifier"
    end

    create_table "tournaments_users", id: false, force: :cascade do |t|
      t.bigint "tournament_id", null: false
      t.bigint "user_id", null: false
      t.index ["user_id", "tournament_id"], name: "index_tournaments_users_on_user_id_and_tournament_id", unique: true
    end

    add_foreign_key "testing_environments", "tournaments"
  end
end
