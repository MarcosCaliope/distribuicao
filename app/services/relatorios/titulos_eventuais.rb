module Relatorios
  # Replica frmRelTitulos.frm, modo "Eventuais": títulos distribuídos no período com
  # status='G' (registrados manualmente, não vindos de remessa bancária — ver
  # frmExportaTitulos.frm#GeraDetalheEventual, Etapa 4). Como este app ainda não tem uma
  # feature de cadastro manual de título, nenhum título hoje satisfaz esse filtro — o filtro
  # em si é fiel ao legado mesmo assim, só está vazio até essa feature existir.
  class TitulosEventuais
    F = Formatacao

    def initialize(data_inicio:, data_fim:, apresentante_prefixo: nil)
      @data_inicio = data_inicio
      @data_fim = data_fim
      @apresentante_prefixo = apresentante_prefixo
    end

    def gerar
      titulos = Titulo.distribuidos
                       .where(status: "G")
                       .where.not(tipo_titulo_id: nil)
                       .where(data_distribuicao: @data_inicio..@data_fim)
                       .includes(:apresentante, :cartorio)
                       .order(:data_distribuicao)

      if @apresentante_prefixo.present?
        titulos = titulos.joins(:apresentante).where("apresentantes.nome ILIKE ?", "#{@apresentante_prefixo}%")
      end

      Dataset.new(
        titulo: "Títulos Eventuais",
        subtitulo: "#{F.data(@data_inicio)} a #{F.data(@data_fim)}",
        colunas: [ "Protocolo", "Título", "Devedor", "Apresentante", "Cartório", "Valor" ],
        linhas: titulos.map { |titulo| linha(titulo) }
      )
    end

    private

    def linha(titulo)
      [
        titulo.numero_protocolo_distribuido,
        titulo.numero_titulo,
        titulo.nome_devedor,
        titulo.apresentante&.nome,
        titulo.cartorio&.nome,
        F.moeda(titulo.valor)
      ]
    end
  end
end
