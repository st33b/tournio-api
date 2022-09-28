class CreateExternalPayments < ActiveRecord::Migration[7.0]
  def change
    create_table :external_payments do |t|
      t.integer :payment_type, null: false
      t.string :identifier, index: true
      t.jsonb :details
      t.references :tournament, index: true

      t.timestamps
    end

    remove_column :purchases, :paypal_order_id, :integer
    add_reference :purchases, :external_payment
  end
end
