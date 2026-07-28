class CreatePerfilPermissoes < ActiveRecord::Migration[8.0]
  def change
    create_table :perfil_permissoes do |t|
      t.references :perfil, null: false, foreign_key: true
      t.references :permissao, null: false, foreign_key: true

      t.timestamps
    end

    add_index :perfil_permissoes, [ :perfil_id, :permissao_id ], unique: true
  end
end
