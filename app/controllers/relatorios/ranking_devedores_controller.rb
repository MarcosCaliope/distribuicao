module Relatorios
  class RankingDevedoresController < ApplicationController
    def index
      @dataset = Relatorios::RankingDevedores.new(
        data_inicio: data_inicio, data_fim: data_fim,
        limite: params[:limite].presence&.to_i || 100,
        faixa_minima: params[:faixa_minima].presence&.to_i,
        faixa_maxima: params[:faixa_maxima].presence&.to_i
      ).gerar
      renderizar(@dataset)
    end
  end
end
