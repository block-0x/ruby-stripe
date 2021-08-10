class CreatePayInfos < ActiveRecord::Migration[6.1]
  def change
    create_table :pay_infos do |t|
      t.string :email
      t.string :description
      t.string :currency
      t.integer :customer_id
      t.time :payment_date
      t.string :payment_status
      t.string :uuid
      t.integer :charge_id
      t.integer :stripe_commission
      t.integer :amount_after_subtract_commission
      t.string :receipt_url

      t.timestamps
    end
  end
end
