module Relatorios
  # Replica frmRelRankingDevedor.frm: devedores com mais títulos distribuídos num período
  # ("reincidentes"), limitado a N (padrão 100, como o legado) e opcionalmente filtrado por
  # uma faixa de quantidade de ocorrências.
  class RankingDevedores
    F = Formatacao

    def initialize(data_inicio:, data_fim:, limite: 100, faixa_minima: nil, faixa_maxima: nil)
      @data_inicio = data_inicio
      @data_fim = data_fim
      @limite = limite
      @faixa_minima = faixa_minima
      @faixa_maxima = faixa_maxima
    end

    def gerar
      contagens = Titulo.distribuidos.where(data_distribuicao: @data_inicio..@data_fim).group(:devedor_id).count
      contagens = contagens.select { |_id, qtd| qtd >= @faixa_minima } if @faixa_minima
      contagens = contagens.select { |_id, qtd| qtd <= @faixa_maxima } if @faixa_maxima
      top = contagens.sort_by { |_devedor_id, qtd| -qtd }.first(@limite)
      devedores = Devedor.where(id: top.map(&:first)).index_by(&:id)

      Dataset.new(
        titulo: "Ranking de Devedores",
        subtitulo: "#{F.data(@data_inicio)} a #{F.data(@data_fim)} — top #{@limite}",
        colunas: [ "Devedor", "CPF/CNPJ", "Quantidade de Títulos" ],
        linhas: top.map { |devedor_id, quantidade| linha(devedores[devedor_id], quantidade) }
      )
    end

    private

    def linha(devedor, quantidade)
      [ devedor&.nome, devedor&.cpf_cnpj, quantidade ]
    end
  end
end
