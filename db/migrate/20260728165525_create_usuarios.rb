class CreateUsuarios < ActiveRecord::Migration[8.0]
  def change
    create_table :usuarios do |t|
      t.string :login, null: false
      t.string :nome, null: false
      t.string :password_digest, null: false
      t.boolean :ativo, null: false, default: true
      t.boolean :deve_trocar_senha, null: false, default: false

      t.timestamps
    end
    add_index :usuarios, :login, unique: true
  end
end
