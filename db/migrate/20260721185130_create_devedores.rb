class CreateDevedores < ActiveRecord::Migration[8.0]
  def change
    create_table :devedores do |t|
      # CPF ou CNPJ; a chave natural do legado é o par (tipo_documento, cpf_cnpj)
      t.string :tipo_documento, limit: 3, null: false
      t.string :cpf_cnpj, limit: 14, null: false
      t.string :nome
      t.string :endereco
      t.string :bairro
      t.string :cep
      t.string :observacao
      t.integer :quantidade_titulos_pendentes, null: false, default: 0

      t.timestamps
    end
    add_index :devedores, [ :tipo_documento, :cpf_cnpj ], unique: true
    add_index :devedores, :nome
  end
end
