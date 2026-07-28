class CreatePerfilUsuarios < ActiveRecord::Migration[8.0]
  def change
    create_table :perfil_usuarios do |t|
      t.references :usuario, null: false, foreign_key: true
      t.references :perfil, null: false, foreign_key: true

      t.timestamps
    end

    add_index :perfil_usuarios, [ :usuario_id, :perfil_id ], unique: true
  end
end
