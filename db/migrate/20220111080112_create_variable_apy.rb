class CreateVariableApy < ActiveRecord::Migration
  def change
    create_table :variable_apy do |t|
      t.references :stake_coin
      t.decimal :lot_size, precision: 32, scale: 16, default: 0.0
      t.decimal :apy, precision: 8, scale: 4
      t.timestamps null: false
    end
  end
end