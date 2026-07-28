class AddExportacaoFksToTitulos < ActiveRecord::Migration[8.0]
  def change
    add_reference :titulos, :manifesto_distribuidor, foreign_key: true
    add_reference :titulos, :retorno_exportado, foreign_key: true
  end
end
