class CreateContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :contacts do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :hubspot_id
      t.string  :name
      t.string  :email

      t.timestamps
    end
    add_index :contacts, [:user_id, :hubspot_id], unique: true
    add_index :contacts, [:user_id, :email]
    add_index :contacts, :name
  end
end