module Relatorios
  # Autenticação (usuário logado) já vem de ApplicationController/Autenticacao por herança.
  # Autorização de verdade (Etapa 6, substitui a trava provisória de HTTP Basic Auth da
  # Etapa 5): só quem tem a permissão "ver_relatorios" (ver RelatorioPolicy) acessa qualquer
  # relatório.
  class ApplicationController < ::ApplicationController
    before_action { authorize :relatorio, :ver? }

    private

    # Responde em HTML (a view padrão da action) ou PDF (via Relatorios::TabelaPdf) — o mesmo
    # par de formatos pra qualquer relatório, então fica aqui em vez de repetido em cada
    # controller.
    def renderizar(dataset)
      respond_to do |format|
        format.html
        format.pdf do
          if dataset
            send_data Relatorios::TabelaPdf.new(dataset).renderizar,
                      filename: "#{dataset.titulo.parameterize}.pdf",
                      type: "application/pdf", disposition: "inline"
          else
            head :unprocessable_entity
          end
        end
      end
    end

    def data_inicio
      params[:data_inicio].presence ? Date.parse(params[:data_inicio]) : 30.days.ago.to_date
    end

    def data_fim
      params[:data_fim].presence ? Date.parse(params[:data_fim]) : Date.current
    end
  end
end
