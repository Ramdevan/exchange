class CreateLoginhistories < ActiveRecord::Migration
  def change
    create_table :loginhistories do |t|
      t.integer :member_id
      t.string :ip_address
      t.datetime :login_time
      t.string :country
      t.string :os
      t.string :browser

      t.timestamps null: false
    end
  end
end
