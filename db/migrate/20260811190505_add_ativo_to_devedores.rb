class AddAtivoToDevedores < ActiveRecord::Migration[8.0]
  def change
    add_column :devedores, :ativo, :boolean, null: false, default: true
  end
end
