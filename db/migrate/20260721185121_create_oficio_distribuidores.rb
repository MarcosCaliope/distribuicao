class CreateOficioDistribuidores < ActiveRecord::Migration[8.0]
  def change
    create_table :oficio_distribuidores do |t|
      t.string :codigo_legado, limit: 6
      t.string :nome, null: false

      t.timestamps
    end
    add_index :oficio_distribuidores, :codigo_legado, unique: true
  end
end
