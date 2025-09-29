class CreateInstructions < ActiveRecord::Migration[7.1]
  def change
    create_table :instructions do |t|
      t.references :user, null: false, foreign_key: true
      t.text    :rule_text, null: false
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end
    add_index :instructions, [:user_id, :is_active]
  end
end