class CreateValidacaoSombraExecucoes < ActiveRecord::Migration[8.0]
  def change
    create_table :validacao_sombra_execucoes do |t|
      t.date :data_inicio, null: false
      t.date :data_fim, null: false
      t.integer :arquivos_processados, null: false, default: 0
      t.integer :titulos_comparados, null: false, default: 0
      t.integer :titulos_batendo, null: false, default: 0
      t.jsonb :arquivos_com_erro, null: false, default: []
      t.jsonb :mismatches, null: false, default: []

      t.timestamps
    end
  end
end
