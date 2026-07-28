module Relatorios
  # Renderizador de PDF compartilhado por todo relatório — troca os blocos duplicados de
  # Viewer/Impressora/Exportar-PDF do legado (copiados em cada tela) por um único caminho: todo
  # relatório vira um Relatorios::Dataset, e esse Dataset vira uma tabela em PDF, sempre do
  # mesmo jeito.
  class TabelaPdf
    def initialize(dataset)
      @dataset = dataset
    end

    def renderizar
      Prawn::Document.new(page_layout: :landscape, margin: 36) do |pdf|
        pdf.text @dataset.titulo, size: 16, style: :bold
        pdf.text @dataset.subtitulo, size: 10, color: "666666" if @dataset.subtitulo.present?
        pdf.move_down 12

        if @dataset.linhas.empty?
          pdf.text "Nenhum registro encontrado."
        else
          pdf.table([ @dataset.colunas ] + @dataset.linhas, header: true, width: pdf.bounds.width) do |table|
            table.row(0).font_style = :bold
            table.row(0).background_color = "DDDDDD"
            table.cells.size = 8
            table.cells.padding = 4
          end
        end
      end.render
    end
  end
end
