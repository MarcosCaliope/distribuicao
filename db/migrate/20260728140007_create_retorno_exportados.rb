class CreateRetornoExportados < ActiveRecord::Migration[8.0]
  def change
    create_table :retorno_exportados do |t|
      t.references :cartorio, null: false, foreign_key: true
      t.references :apresentante, null: false, foreign_key: true
      t.date :data, null: false
      t.integer :quantidade_titulos, null: false, default: 0
      t.datetime :enviado_em

      t.timestamps
    end

    add_index :retorno_exportados, [ :cartorio_id, :apresentante_id, :data ],
              unique: true, name: "index_retorno_exportados_on_cartorio_apresentante_data"
  end
end
