class CreateManifestoDistribuidores < ActiveRecord::Migration[8.0]
  def change
    create_table :manifesto_distribuidores do |t|
      t.references :oficio_distribuidor, null: false, foreign_key: true
      t.date :data, null: false
      t.integer :quantidade_titulos, null: false, default: 0

      t.timestamps
    end

    add_index :manifesto_distribuidores, [ :oficio_distribuidor_id, :data ],
              unique: true, name: "index_manifesto_distribuidores_on_oficio_data"
  end
end
