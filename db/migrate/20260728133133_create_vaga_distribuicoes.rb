class CreateVagaDistribuicoes < ActiveRecord::Migration[8.0]
  def change
    create_table :vaga_distribuicoes do |t|
      t.date :data, null: false
      t.references :cartorio, null: false, foreign_key: true
      t.references :faixa_custa, null: false, foreign_key: true
      t.boolean :livre, null: false, default: false
      t.integer :quantidade_titulos, null: false, default: 0

      t.timestamps
    end

    add_index :vaga_distribuicoes, [ :data, :cartorio_id, :faixa_custa_id ],
              unique: true, name: "index_vaga_distribuicoes_on_data_cartorio_faixa"
    add_index :vaga_distribuicoes, [ :data, :faixa_custa_id, :livre ]
  end
end
