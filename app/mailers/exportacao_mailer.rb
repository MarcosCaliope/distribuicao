class ExportacaoMailer < ApplicationMailer
  # E-mail do retorno por cartório+apresentante (ver app/services/exportacao/gerador_retorno.rb).
  # O destinatário é o cartório, não o banco/apresentante — correção em relação à descrição
  # solta em docs/ANALISE_MIGRACAO.md, confirmada lendo o legado (frmExportaTitulos.frm): o
  # assunto do e-mail legado é literalmente "Arquivos da Distribuição, Ofício " & pro_id.
  def retorno(retorno_exportado)
    @retorno_exportado = retorno_exportado

    attachments[retorno_exportado.arquivo.filename.to_s] = retorno_exportado.arquivo.download

    mail(
      to: retorno_exportado.cartorio.email,
      cc: retorno_exportado.cartorio.email_copia.presence,
      subject: "Arquivos da Distribuição - #{retorno_exportado.cartorio.nome}"
    )
  end
end
