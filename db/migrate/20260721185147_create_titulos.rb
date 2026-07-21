class CreateTitulos < ActiveRecord::Migration[8.0]
  def change
    create_table :titulos do |t|
      # Identidade estável: "id" é a chave real. "protocolo_original" é o
      # valor emitido por seq_protocolo no momento da importação (imutável).
      # "numero_protocolo_distribuido" é o código exibido/impresso depois da
      # distribuição (cartório + ofício + protocolo_original), calculado uma
      # vez pelo serviço de distribuição (Etapa 3) — nunca reescrito depois.
      # No VB6 o "protocolo" é um único campo mutado in-place; aqui separamos
      # de propósito para não herdar esse comportamento.
      t.string :protocolo_original, null: false
      t.string :numero_protocolo_distribuido

      t.references :devedor, null: false, foreign_key: true
      # Snapshot do devedor no momento do título (endereço pode divergir do
      # cadastro atual em cad_devedor/devedores — mesmo padrão do legado).
      t.string :tipo_documento_devedor, limit: 3, null: false
      t.string :cpf_cnpj_devedor, limit: 14, null: false
      t.string :nome_devedor
      t.string :endereco_devedor
      t.string :cep_devedor
      t.string :cidade_devedor
      t.string :uf_devedor, limit: 2

      t.references :tipo_titulo, null: false, foreign_key: true
      t.string :numero_titulo, null: false

      t.date :data_emissao
      t.date :data_vencimento
      t.date :data_recebimento, null: false
      t.date :data_distribuicao

      t.decimal :valor, precision: 12, scale: 2, null: false

      t.references :apresentante, foreign_key: true
      t.string :cedente

      t.string :nome_sacador
      t.string :documento_sacador
      t.string :endereco_sacador
      t.string :cep_sacador
      t.string :cidade_sacador
      t.string :uf_sacador, limit: 2

      t.references :cartorio, foreign_key: true
      t.references :oficio_distribuidor, foreign_key: true

      t.string :codigo_banco
      t.string :codigo_agencia

      # Estados observados no legado incluem ao menos "G" (gerado/eventual).
      # Lista completa a confirmar antes de virar enum.
      t.string :status, null: false, default: "G"
      t.boolean :efeito_falencia, null: false, default: false

      t.references :irregularidade, foreign_key: true
      t.string :tipo_ocorrencia, limit: 1

      # Referência ao arquivo de remessa de origem; vira FK para um model
      # Remessa próprio na Etapa 2 (import).
      t.string :nome_arquivo_remessa

      t.timestamps
    end
    add_index :titulos, :protocolo_original, unique: true
    add_index :titulos, :numero_protocolo_distribuido, unique: true
    add_index :titulos, :numero_titulo
    add_index :titulos, :data_recebimento
    add_index :titulos, :data_distribuicao
  end
end
