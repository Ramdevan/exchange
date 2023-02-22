class CreateMissingBlocks < ActiveRecord::Migration
  def change
    create_table :missing_blocks do |t|
      t.integer :block_id
      t.string :currency
      t.boolean :status

      t.timestamps null: false
    end
  end
end
