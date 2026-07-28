module Relatorios
  # Replica frmRelTitulos.frm, modo "Por Devedor": sem filtro de data (o legado tem literalmente
  # uma cláusula WHERE vazia antes de "tipo_tit<>'*'" nesse modo — não é bug, é como o modo
  # funciona), filtrado por prefixo do CPF/CNPJ do devedor.
  class TitulosPorDevedor
    F = Formatacao

    def initialize(cpf_cnpj_prefixo:)
      @cpf_cnpj_prefixo = cpf_cnpj_prefixo
    end

    def gerar
      titulos = Titulo.distribuidos
                       .where.not(tipo_titulo_id: nil)
                       .where("cpf_cnpj_devedor LIKE ?", "#{@cpf_cnpj_prefixo}%")
                       .includes(:cartorio, :apresentante)
                       .order(:data_distribuicao)

      Dataset.new(
        titulo: "Títulos por Devedor",
        subtitulo: "CPF/CNPJ começando com #{@cpf_cnpj_prefixo}",
        colunas: [ "Protocolo", "Título", "Devedor", "Cartório", "Apresentante", "Valor" ],
        linhas: titulos.map { |titulo| linha(titulo) }
      )
    end

    private

    def linha(titulo)
      [
        titulo.numero_protocolo_distribuido,
        titulo.numero_titulo,
        titulo.nome_devedor,
        titulo.cartorio&.nome,
        titulo.apresentante&.nome,
        F.moeda(titulo.valor)
      ]
    end
  end
end
