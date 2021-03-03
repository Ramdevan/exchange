class CreateWhitelistings < ActiveRecord::Migration
  def change
    create_table :whitelistings do |t|
      t.integer :member_id
      t.string :ip_address
      t.string :token
      t.datetime :expired_at
      t.boolean :authorised_ip, default: false

      t.timestamps null: false
    end
  end
end
