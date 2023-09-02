class AddIndexToUsersEmail < ActiveRecord::Migration[7.0]

  def change
    add_index :users, :emai, unique: true
  end
end
