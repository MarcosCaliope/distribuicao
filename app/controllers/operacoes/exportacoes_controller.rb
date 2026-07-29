module Operacoes
  class ExportacoesController < ApplicationController
    def new
      @pendentes_manifesto = Titulo.pendentes_manifesto.count
      @pendentes_retorno = Titulo.pendentes_retorno.count
    end

    def create
      data = data_param
      manifestos = Exportacao::GeradorManifesto.new(data: data).gerar
      retornos = Exportacao::GeradorRetorno.new(data: data).gerar
      redirect_to new_operacoes_exportacao_path,
        notice: "#{manifestos.size} manifesto(s) e #{retornos.size} retorno(s) gerados para #{data}."
    end

    private

    def data_param
      params[:data].presence ? Date.parse(params[:data]) : Date.current
    end
  end
end
