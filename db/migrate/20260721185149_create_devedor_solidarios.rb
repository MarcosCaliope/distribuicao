class CreateDevedorSolidarios < ActiveRecord::Migration[8.0]
  def change
    create_table :devedor_solidarios do |t|
      t.references :titulo, null: false, foreign_key: true
      t.references :devedor, null: false, foreign_key: true
      t.string :nosso_numero
      t.string :especie, limit: 3

      t.timestamps
    end
    add_index :devedor_solidarios, [ :titulo_id, :devedor_id ], unique: true, name: "index_devedor_solidarios_on_titulo_and_devedor"
  end
end
