class AddAtivoToBancos < ActiveRecord::Migration[8.0]
  def change
    add_column :bancos, :ativo, :boolean, null: false, default: true
  end
end
