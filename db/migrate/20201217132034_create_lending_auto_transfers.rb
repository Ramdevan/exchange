class CreateLendingAutoTransfers < ActiveRecord::Migration
  def change
    create_table :lending_auto_transfers do |t|
      t.string :currency
      t.boolean :is_auto_transfer
      t.references :member, index: true, foreign_key: true
      t.references :lending, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
