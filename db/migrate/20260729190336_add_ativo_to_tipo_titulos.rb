class AddAtivoToTipoTitulos < ActiveRecord::Migration[8.0]
  def change
    add_column :tipo_titulos, :ativo, :boolean, null: false, default: true
  end
end
