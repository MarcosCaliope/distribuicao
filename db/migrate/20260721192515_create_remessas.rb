class CreateRemessas < ActiveRecord::Migration[8.0]
  def change
    create_table :remessas do |t|
      # Nome do arquivo é a chave de deduplicação (equivalente ao check
      # "já foi importado" do legado, hoje feito contra tblremessas).
      t.string :nome_arquivo, null: false
      t.references :banco, foreign_key: true
      t.references :apresentante, foreign_key: true
      t.string :numero_remessa
      t.integer :quantidade_registros_transacao
      t.integer :quantidade_titulos
      t.integer :quantidade_indicacoes
      t.integer :quantidade_originais
      t.string :status, null: false, default: "pendente"
      t.text :mensagem_erro

      t.timestamps
    end
    add_index :remessas, :nome_arquivo, unique: true
  end
end
