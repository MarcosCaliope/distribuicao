module Relatorios
  # Replica frmRelArrecadacaoNew2.frm, botão "Imprimir" (RelArrecadacao): resumo diário de
  # títulos por ofício distribuidor x convênio do apresentante. O legado mistura contagens de
  # Escrituras/Testamentos nessa mesma tela — nenhum dos dois é modelado neste app (fora do
  # MVP), então esse relatório cobre só títulos. Também não replica o efeito colateral do
  # legado (`UPDATE cad_titulos SET sefeitofalencia='Y' ...` disparado por só gerar o
  # relatório) — ver item 13 de docs/ANALISE_MIGRACAO.md. Leitura pura.
  class ArrecadacaoResumo
    F = Formatacao
    LEGENDA_CONVENIO = { "C" => "CDA", "I" => "Isento", "B" => "Banco" }.freeze

    def initialize(data_inicio:, data_fim:)
      @data_inicio = data_inicio
      @data_fim = data_fim
    end

    def gerar
      titulos = Titulo.distribuidos
                       .where(data_distribuicao: @data_inicio..@data_fim)
                       .includes(:oficio_distribuidor, :apresentante)

      grupos = titulos.group_by { |t| [ t.data_distribuicao, t.oficio_distribuidor&.nome, t.apresentante&.convenio ] }
                       .sort_by { |(data, oficio, _convenio), _grupo| [ data, oficio.to_s ] }

      Dataset.new(
        titulo: "Arrecadação",
        subtitulo: "#{F.data(@data_inicio)} a #{F.data(@data_fim)} — só títulos " \
                   "(Escrituras/Testamentos fora de escopo, ver docs/ANALISE_MIGRACAO.md)",
        colunas: [ "Data", "Ofício Distribuidor", "Convênio", "Quantidade" ],
        linhas: grupos.map { |(data, oficio, convenio), grupo| linha(data, oficio, convenio, grupo) }
      )
    end

    private

    def linha(data, oficio, convenio, grupo)
      [ F.data(data), oficio || "—", LEGENDA_CONVENIO.fetch(convenio, "—"), grupo.size ]
    end
  end
end
