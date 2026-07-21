class AddRemessaToTitulos < ActiveRecord::Migration[8.0]
  def change
    remove_column :titulos, :nome_arquivo_remessa, :string
    add_reference :titulos, :remessa, foreign_key: true
  end
end
