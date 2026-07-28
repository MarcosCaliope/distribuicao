module Relatorios
  class TitulosController < ApplicationController
    def eventuais
      @dataset = Relatorios::TitulosEventuais.new(
        data_inicio: data_inicio, data_fim: data_fim, apresentante_prefixo: params[:apresentante]
      ).gerar
      renderizar(@dataset)
    end

    def por_apresentante
      if params[:apresentante_id].present?
        @dataset = Relatorios::TitulosPorApresentante.new(
          data_inicio: data_inicio, data_fim: data_fim,
          apresentante_id: params[:apresentante_id], sintetico: ActiveModel::Type::Boolean.new.cast(params[:sintetico])
        ).gerar
      end
      @apresentantes = Apresentante.order(:nome)
      renderizar(@dataset)
    end

    def por_devedor
      if params[:cpf_cnpj].present?
        @dataset = Relatorios::TitulosPorDevedor.new(cpf_cnpj_prefixo: params[:cpf_cnpj]).gerar
      end
      renderizar(@dataset)
    end
  end
end
