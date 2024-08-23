class CreateTickets < ActiveRecord::Migration[7.1]
  def change
    create_table :tickets do |t|
      t.references :event, null: false, foreign_key: true
      t.integer :user_id
      t.integer :expired_at

      t.timestamps
    end
  end
end
