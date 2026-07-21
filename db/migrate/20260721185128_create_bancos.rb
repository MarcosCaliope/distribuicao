class CreateBancos < ActiveRecord::Migration[8.0]
  def change
    create_table :bancos do |t|
      t.string :codigo_legado, limit: 6, null: false
      t.string :codigo_alfa, limit: 6
      t.string :nome, null: false
      t.references :apresentante, foreign_key: true
      t.decimal :valor_custa, precision: 12, scale: 2
      t.boolean :processa, null: false, default: true
      t.boolean :gera_remessa_cartorio, null: false, default: true
      t.integer :sequencia_confirmacao
      t.string :email

      t.timestamps
    end
    add_index :bancos, :codigo_legado, unique: true
    add_index :bancos, :codigo_alfa, unique: true
  end
end
