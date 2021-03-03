class AddBankCodeToFundSources < ActiveRecord::Migration
  def change
    add_column :fund_sources, :bank_code, :string
  end
end
