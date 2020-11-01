class AddNameInDocument < ActiveRecord::Migration
  def change
    rename_column :id_documents, :name, :first_name
    add_column :id_documents, :last_name, :string

    remove_column :members, :display_name
    remove_column :members, :nickname
  end
end