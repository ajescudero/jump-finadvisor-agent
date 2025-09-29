class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :kind, null: false               # e.g., "schedule_meeting", "await_reply", ...
      t.text    :payload_json, null: false       # JSON with parameters/state
      t.string  :status, null: false, default: "pending" # pending|running|waiting|done|failed
      t.text    :last_error

      t.timestamps
    end
    add_index :tasks, [:user_id, :status]
    add_index :tasks, :kind
  end
end