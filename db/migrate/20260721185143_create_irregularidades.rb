class CreateIrregularidades < ActiveRecord::Migration[8.0]
  def change
    create_table :irregularidades do |t|
      # Normaliza os ~70 códigos hoje hardcoded em FrmCadTitulos.labelIrreg()
      # (icodirregularidade). Descrições ainda precisam ser extraídas do VB6
      # e semeadas (seed) — não foram inventadas aqui.
      t.integer :codigo, null: false
      t.string :descricao, null: false

      t.timestamps
    end
    add_index :irregularidades, :codigo, unique: true
  end
end
