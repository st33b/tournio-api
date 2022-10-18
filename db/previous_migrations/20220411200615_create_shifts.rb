class CreateShifts < ActiveRecord::Migration[7.0]
  def change
    create_table :shifts do |t|
      t.string :identifier, null: false, unique: true
      t.string :name
      t.string :description
      t.jsonb :details, default: {events: [], permit_new_teams: true, permit_solo: true, permit_joins: true}
      t.integer :display_order, null: false, default: 1
      t.integer :capacity, null: false, default: 128
      t.integer :requested, null: false, default: 0
      t.integer :confirmed, null: false, default: 0
      t.references :tournament, null: false

      t.timestamps

      t.index :identifier, unique: true
    end
  end
end
