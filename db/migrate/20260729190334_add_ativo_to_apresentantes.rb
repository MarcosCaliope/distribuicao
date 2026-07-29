class AddAtivoToApresentantes < ActiveRecord::Migration[8.0]
  def change
    add_column :apresentantes, :ativo, :boolean, null: false, default: true
  end
end
