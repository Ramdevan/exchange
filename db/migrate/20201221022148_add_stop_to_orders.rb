class AddStopToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :stop_price, :decimal, precision: 32, scale: 16
    add_column :orders, :trigger_cond, :string, limit: 10
  end
end
