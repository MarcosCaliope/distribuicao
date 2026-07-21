class CreateCartorios < ActiveRecord::Migration[8.0]
  def change
    create_table :cartorios do |t|
      t.string :codigo_legado, limit: 6
      t.string :nome, null: false
      t.string :oficial
      t.string :telefone
      t.string :email
      t.string :email_copia
      t.boolean :ativo, null: false, default: true

      t.timestamps
    end
    add_index :cartorios, :codigo_legado, unique: true
  end
end
