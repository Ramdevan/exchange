class AddBankCodeToWithdraws < ActiveRecord::Migration
  def change
    add_column :withdraws, :bank_code, :string
  end
end
