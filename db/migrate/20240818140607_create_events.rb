class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.string :name
      t.integer :capacity
      t.integer :timeout

      t.timestamps
    end
  end
end
