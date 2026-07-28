class CreatePermissoes < ActiveRecord::Migration[8.0]
  def change
    create_table :permissoes do |t|
      t.string :chave, null: false

      t.timestamps
    end
    add_index :permissoes, :chave, unique: true
  end
end
