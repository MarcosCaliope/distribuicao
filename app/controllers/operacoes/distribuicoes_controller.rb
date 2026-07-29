module Operacoes
  class DistribuicoesController < ApplicationController
    def new
      @pendentes = Titulo.pendentes_distribuicao.count
    end

    def create
      falhas = Distribuicao::Processador.new(data: data_param).processar
      if falhas.empty?
        redirect_to new_operacoes_distribuicao_path, notice: "Distribuição de #{data_param} concluída sem falhas."
      else
        redirect_to new_operacoes_distribuicao_path,
          alert: "#{falhas.size} falha(s): #{falhas.map(&:mensagem).join('; ')}"
      end
    end

    def destroy
      Distribuicao::Desfazedor.new(data_param).desfazer!
      redirect_to new_operacoes_distribuicao_path, notice: "Distribuição de #{data_param} desfeita."
    end

    private

    def data_param
      params[:data].presence ? Date.parse(params[:data]) : Date.current
    end
  end
end
