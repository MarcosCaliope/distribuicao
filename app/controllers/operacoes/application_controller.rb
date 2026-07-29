module Operacoes
  # Fase 0 da Etapa 8 (ver docs/ANALISE_MIGRACAO.md): pontos de entrada em produção pra
  # RemessaImportacao::Importador, Distribuicao::Processador e Exportacao::Gerador*, que até
  # aqui só eram exercitados por teste. Uma única permissão (operar_distribuicao) gate todas
  # as três telas — não há distinção hoje entre quem importa, distribui e exporta.
  class ApplicationController < ::ApplicationController
    before_action { authorize :operacao, :executar? }
  end
end
