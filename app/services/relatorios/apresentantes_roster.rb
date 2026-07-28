module Relatorios
  # Replica frmCadApresentantes.frm, botão "Imprimir": roster de apresentantes, com 5
  # modos de ordenação/filtro (alfabética/numérica/CDA/isentos/bancos) — listagem de
  # referência, sem filtro de data.
  class ApresentantesRoster
    MODOS = {
      "alfabetica" => "Ordem alfabética",
      "numerica" => "Ordem numérica",
      "cda" => "Somente CDAs",
      "isentos" => "Somente isentos",
      "bancos" => "Somente bancos"
    }.freeze

    def initialize(modo: "alfabetica")
      @modo = MODOS.key?(modo) ? modo : "alfabetica"
    end

    def gerar
      Dataset.new(
        titulo: "Cadastro de Apresentantes",
        subtitulo: MODOS.fetch(@modo),
        colunas: [ "Código", "Nome", "Convênio" ],
        linhas: apresentantes.map { |apresentante| [ apresentante.codigo_legado, apresentante.nome, apresentante.convenio ] }
      )
    end

    private

    def apresentantes
      case @modo
      when "numerica" then Apresentante.order(:codigo_legado)
      when "cda" then Apresentante.where(convenio: "C").order(:nome)
      when "isentos" then Apresentante.where(convenio: "I").order(:nome)
      when "bancos" then Apresentante.where(convenio: "B").order(:nome)
      else Apresentante.order(:nome)
      end
    end
  end
end
