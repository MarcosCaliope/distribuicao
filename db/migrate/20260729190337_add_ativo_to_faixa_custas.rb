class AddAtivoToFaixaCustas < ActiveRecord::Migration[8.0]
  def change
    add_column :faixa_custas, :ativo, :boolean, null: false, default: true
  end
end
