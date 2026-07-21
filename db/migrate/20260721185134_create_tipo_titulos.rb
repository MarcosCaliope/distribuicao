class CreateTipoTitulos < ActiveRecord::Migration[8.0]
  def change
    create_table :tipo_titulos do |t|
      t.string :codigo_legado, limit: 2, null: false
      t.string :descricao, null: false
      # Abreviação lida no byte 214-216 do registro de detalhe da remessa (ex.: DMI, DRI, CBI)
      t.string :abreviatura, limit: 3, null: false

      t.timestamps
    end
    add_index :tipo_titulos, :codigo_legado, unique: true
    add_index :tipo_titulos, :abreviatura, unique: true
  end
end
