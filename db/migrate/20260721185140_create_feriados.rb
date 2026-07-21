class CreateFeriados < ActiveRecord::Migration[8.0]
  def change
    create_table :feriados do |t|
      t.date :data, null: false
      t.string :descricao, null: false

      t.timestamps
    end
    add_index :feriados, :data, unique: true
  end
end
