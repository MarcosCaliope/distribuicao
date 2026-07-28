module Relatorios
  # Replica frmRelTitulos.frm, modo "Por Apresentante": mesma consulta, dois relatórios no
  # legado (analítico x sintético via chkSintetico) — aqui, mesmo serviço, dois formatos de
  # saída. O agrupamento do sintético (por cartório) é uma suposição, não confirmada contra o
  # .rpt original (binário, ilegível) — ver docs/ANALISE_MIGRACAO.md, Etapa 5.
  class TitulosPorApresentante
    F = Formatacao

    def initialize(data_inicio:, data_fim:, apresentante_id:, sintetico: false)
      @data_inicio = data_inicio
      @data_fim = data_fim
      @apresentante_id = apresentante_id
      @sintetico = sintetico
    end

    def gerar
      apresentante = Apresentante.find(@apresentante_id)
      titulos = Titulo.distribuidos
                       .where.not(tipo_titulo_id: nil)
                       .where(data_distribuicao: @data_inicio..@data_fim, apresentante_id: @apresentante_id)
                       .includes(:cartorio)
                       .order(:data_distribuicao)

      Dataset.new(
        titulo: @sintetico ? "Títulos por Apresentante (Sintético)" : "Títulos por Apresentante",
        subtitulo: "#{apresentante.nome} — #{F.data(@data_inicio)} a #{F.data(@data_fim)}",
        colunas: @sintetico ? colunas_sintetico : colunas_detalhe,
        linhas: @sintetico ? linhas_sintetico(titulos) : linhas_detalhe(titulos)
      )
    end

    private

    def colunas_detalhe
      [ "Protocolo", "Título", "Devedor", "Cartório", "Valor" ]
    end

    def colunas_sintetico
      [ "Cartório", "Quantidade", "Valor Total" ]
    end

    def linhas_detalhe(titulos)
      titulos.map do |titulo|
        [ titulo.numero_protocolo_distribuido, titulo.numero_titulo, titulo.nome_devedor,
          titulo.cartorio&.nome, F.moeda(titulo.valor) ]
      end
    end

    def linhas_sintetico(titulos)
      titulos.group_by(&:cartorio).map do |cartorio, grupo|
        [ cartorio&.nome || "—", grupo.size, F.moeda(grupo.sum(&:valor)) ]
      end
    end
  end
end
