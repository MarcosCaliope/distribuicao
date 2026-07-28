module Relatorios
  # Trava provisória de acesso (não é Etapa 6 — autenticação de verdade com usuário/senha real
  # ainda não existe neste app). Só o suficiente pra não deixar os relatórios, que expõem dado
  # pessoal de devedores, completamente abertos até a Etapa 6 chegar.
  class ApplicationController < ::ApplicationController
    # Sem credencial configurada (credentials ou ENV), cai pra um valor aleatório por boot —
    # não abre a tela sem querer, sem derrubar o app inteiro por falta de configuração.
    http_basic_authenticate_with(
      name: Rails.application.credentials.dig(:relatorios, :usuario) || ENV["RELATORIOS_USUARIO"] || SecureRandom.hex(8),
      password: Rails.application.credentials.dig(:relatorios, :senha) || ENV["RELATORIOS_SENHA"] || SecureRandom.hex(8)
    )

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
