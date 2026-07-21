class CreateApresentantes < ActiveRecord::Migration[8.0]
  def change
    create_table :apresentantes do |t|
      t.string :codigo_legado, limit: 6
      t.string :nome, null: false
      t.string :endereco
      t.string :telefone
      t.string :contato
      t.string :agencia
      t.string :tipo, limit: 1
      # Convênio: "C" CDA, "I" Isento, "B" Banco (ver cad_apresenta.convenio no legado)
      t.string :convenio, limit: 1
      t.boolean :custa_antecipada, null: false, default: false

      t.timestamps
    end
    add_index :apresentantes, :codigo_legado, unique: true
  end
end
