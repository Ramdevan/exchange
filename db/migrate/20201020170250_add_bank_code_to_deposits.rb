class AddBankCodeToDeposits < ActiveRecord::Migration
  def change
    add_column :deposits, :bank_code, :string
  end
end
