class CreateFaixaCustas < ActiveRecord::Migration[8.0]
  def change
    create_table :faixa_custas do |t|
      # No legado (cad_faixas) só "tipo" é chave primária, mas "isequencial" é
      # a chave de agrupamento realmente usada em toda a lógica de distribuição
      # (bug de modelagem do legado — aqui "sequencial" é único de verdade).
      t.integer :sequencial, null: false
      t.string :tipo, limit: 1, null: false
      t.decimal :valor, precision: 12, scale: 2
      t.integer :numero_cartorios
      t.decimal :quantidade_dia, precision: 12, scale: 2
      t.decimal :limite_inferior, precision: 12, scale: 2, null: false
      t.decimal :limite_superior, precision: 12, scale: 2, null: false

      t.timestamps
    end
    add_index :faixa_custas, :sequencial, unique: true
  end
end
