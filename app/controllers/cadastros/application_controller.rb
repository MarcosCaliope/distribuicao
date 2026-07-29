module Cadastros
  # Etapa 8: telas de CRUD pras tabelas de dimensão (cartórios, bancos, apresentantes, tipos de
  # título, faixas de custa), fechando a "pergunta aberta 2" de docs/ANALISE_MIGRACAO.md — até
  # aqui essas tabelas só existiam via os importadores ETL (Etapa 7, app/services/etl/), sem
  # tela de edição. Uma única permissão (gerenciar_cadastros) gate as 5 telas, restrita ao
  # perfil administrador.
  class ApplicationController < ::ApplicationController
    before_action { authorize :cadastro, :gerenciar? }
  end
end
