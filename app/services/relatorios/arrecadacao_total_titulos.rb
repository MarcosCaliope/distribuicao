module Relatorios
  # Replica frmRelArrecadacaoNew2.frm, botão "Imprimir Total de Títulos" (RelTotTit): total
  # diário de títulos por ofício distribuidor, com a diferença entre os dois (usado pra notar
  # desequilíbrio de volume no rodízio). O legado também abre um detalhamento por cartório
  # (códigos fixos "1","2","5","7","8") — simplificação deliberada aqui: como o Dataset é uma
  # única tabela genérica (ver Relatorios::Dataset) e os códigos de cartório do legado não têm
  # por que corresponder aos cartórios reais deste app (ainda sem dados da Etapa 7), esse
  # detalhamento fica de fora desta versão — o propósito central do relatório (desequilíbrio
  # entre os dois ofícios) é o que fica.
  class ArrecadacaoTotalTitulos
    F = Formatacao

    def initialize(data_inicio:, data_fim:)
      @data_inicio = data_inicio
      @data_fim = data_fim
    end

    def gerar
      titulos = Titulo.distribuidos.where(data_distribuicao: @data_inicio..@data_fim).includes(:oficio_distribuidor)
      por_dia = titulos.group_by(&:data_distribuicao)

      Dataset.new(
        titulo: "Total de Títulos",
        subtitulo: "#{F.data(@data_inicio)} a #{F.data(@data_fim)}",
        colunas: [ "Data", "Ofício 1", "Ofício 2", "Diferença" ],
        linhas: (@data_inicio..@data_fim).map { |data| linha(data, por_dia[data] || []) }
      )
    end

    private

    def linha(data, titulos_do_dia)
      por_oficio = titulos_do_dia.group_by { |titulo| titulo.oficio_distribuidor&.codigo_legado }
      oficio1 = por_oficio["1"]&.size || 0
      oficio2 = por_oficio["2"]&.size || 0
      [ F.data(data), oficio1, oficio2, oficio1 - oficio2 ]
    end
  end
end
