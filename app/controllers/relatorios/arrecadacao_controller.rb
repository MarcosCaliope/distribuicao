module Relatorios
  class ArrecadacaoController < ApplicationController
    def resumo
      @dataset = Relatorios::ArrecadacaoResumo.new(data_inicio: data_inicio, data_fim: data_fim).gerar
      renderizar(@dataset)
    end

    def total_titulos
      @dataset = Relatorios::ArrecadacaoTotalTitulos.new(data_inicio: data_inicio, data_fim: data_fim).gerar
      renderizar(@dataset)
    end
  end
end
