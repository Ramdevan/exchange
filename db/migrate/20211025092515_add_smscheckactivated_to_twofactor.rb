class AddSmscheckactivatedToTwofactor < ActiveRecord::Migration
  def change
    add_column :two_factors, :sms_check_activated, :boolean, default: false
  end
end
