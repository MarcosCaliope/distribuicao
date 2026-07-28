class AddLivreToOficioDistribuidores < ActiveRecord::Migration[8.0]
  def change
    add_column :oficio_distribuidores, :livre, :boolean, null: false, default: true
  end
end
