module Exportacao
  # Envia por e-mail o retorno gerado por GeradorRetorno. O job é a própria fronteira
  # assíncrona — o legado nunca teve isso (era um botão manual disparando uma automação COM
  # síncrona do Outlook, ver docs/ANALISE_MIGRACAO.md); aqui é comportamento novo.
  class EnvioRetornoJob < ApplicationJob
    queue_as :default

    def perform(retorno_exportado_id)
      retorno_exportado = RetornoExportado.find(retorno_exportado_id)
      ExportacaoMailer.retorno(retorno_exportado).deliver_now
      retorno_exportado.update!(enviado_em: Time.current)
    end
  end
end
