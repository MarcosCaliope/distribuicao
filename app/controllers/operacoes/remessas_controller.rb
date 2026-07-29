module Operacoes
  class RemessasController < ApplicationController
    def new
    end

    def create
      arquivo = params.require(:arquivo)
      remessa = RemessaImportacao::Importador.new(
        arquivo.path, nome_arquivo: arquivo.original_filename
      ).importar
      redirect_to new_operacoes_remessa_path,
        notice: "Remessa #{remessa.nome_arquivo} importada: #{remessa.quantidade_titulos} título(s)."
    rescue RemessaImportacao::ErroArquivo => e
      redirect_to new_operacoes_remessa_path, alert: e.message
    end
  end
end
