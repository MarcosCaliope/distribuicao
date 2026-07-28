class CreatePerfis < ActiveRecord::Migration[8.0]
  def change
    create_table :perfis do |t|
      t.string :nome, null: false

      t.timestamps
    end
    add_index :perfis, :nome, unique: true
  end
end
