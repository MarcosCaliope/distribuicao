module Exportacao
  # Gera o manifesto interno por ofício distribuidor, replicando
  # frmExportaTitulosDistribuicao.frm#GeraDetalhe do legado (ver docs/ANALISE_MIGRACAO.md,
  # Etapa 4 e itens 8-11 do histórico de bugs para o que foi deliberadamente corrigido: cada
  # ofício é gerado independentemente (sem abortar o lote todo se um estiver vazio), campos
  # sempre em largura fixa mesmo quando o dado falta (sem deslocar bytes), e sem estourar em
  # títulos com data_vencimento nula. Layout puro de linhas de detalhe, sem header/trailer
  # (confirmado: o legado declara variáveis de header/trailer mas nunca as usa nesse form).
  #
  # Duas divergências deliberadas de layout, ambas por o mesmo motivo: o legado guardava um
  # código mais curto do que o valor real que o Rails guarda hoje, e truncar de volta cortaria
  # dado de verdade. (1) Tipo de documento: 4 bytes aqui, não 3 como no legado
  # (`cad_titulos.tipo_doc varchar(3)`, guardava "CGC"/"CPF") — a Etapa 2 já alargou a coluna
  # pra guardar "CNPJ" (4 chars) em vez do "CGC" arcaico. (2) Tipo de título: 3 bytes aqui, não
  # 2 como no legado (`cad_titulos.tipo_tit varchar(2)`) — `tipo_titulos.abreviatura` é
  # varchar(3) (`"DMI"`/`"DRI"`/`"CBI"`), o mesmo tamanho que o layout de import já usa. Como
  # esse manifesto é um formato novo, só consumido pela própria aplicação (não é trocado com
  # bancos), alargar os dois campos é seguro; o resto da linha desloca 2 bytes a mais do que o
  # `GeraDetalhe` original (304 bytes no total, não 302).
  class GeradorManifesto
    F = FormatoFixo

    MAX_CODEVEDORES = 9

    def initialize(data: Date.current)
      @data = data
    end

    def gerar
      OficioDistribuidor.order(:id).filter_map { |oficio| gerar_para_oficio(oficio) }
    end

    private

    def gerar_para_oficio(oficio)
      titulos = Titulo.pendentes_manifesto
                       .where(data_distribuicao: @data, oficio_distribuidor: oficio)
                       .where.not(tipo_titulo_id: nil)
                       .order(:numero_protocolo_distribuido)
                       .to_a
      return if titulos.empty?

      conteudo = titulos.map { |titulo| linhas_do_titulo(titulo) }.join

      manifesto = nil
      ApplicationRecord.transaction do
        manifesto = ManifestoDistribuidor.create!(
          oficio_distribuidor: oficio, data: @data, quantidade_titulos: titulos.size
        )
        manifesto.arquivo.attach(
          io: StringIO.new(conteudo),
          filename: "manifesto_#{oficio.codigo_legado}_#{@data.strftime('%Y%m%d')}.rem",
          content_type: "text/plain"
        )
        Titulo.where(id: titulos.map(&:id)).update_all(manifesto_distribuidor_id: manifesto.id)
      end
      manifesto
    end

    def linhas_do_titulo(titulo)
      linha = linha_principal(titulo) + "\r\n"

      solidarios = titulo.devedor_solidarios.includes(:devedor).to_a
      if solidarios.size > MAX_CODEVEDORES - 1
        raise ArgumentError, "título #{titulo.id} tem mais de #{MAX_CODEVEDORES - 1} codevedores"
      end

      solidarios.each_with_index do |solidario, indice|
        linha += linha_solidario(titulo, solidario, indice + 2) + "\r\n"
      end
      linha
    end

    def linha_principal(titulo)
      [
        F.texto(titulo.tipo_documento_devedor, 4),
        F.texto(titulo.cpf_cnpj_devedor, 14),
        F.texto(titulo.tipo_titulo&.abreviatura, 3),
        F.texto(titulo.numero_titulo, 15),
        F.data(titulo.data_vencimento),
        F.data(titulo.data_recebimento),
        F.moeda(titulo.valor, 14),
        F.data(titulo.data_distribuicao),
        F.texto(titulo.cartorio&.codigo_legado, 1),
        F.texto(titulo.apresentante&.codigo_legado, 6),
        F.texto(titulo.apresentante&.nome, 45),
        F.texto(titulo.nome_devedor, 50),
        F.texto(titulo.oficio_distribuidor&.codigo_legado, 1),
        F.texto(titulo.status, 2),
        F.texto(titulo.remessa&.banco&.codigo_legado, 3),
        F.texto(titulo.codigo_agencia, 7),
        F.numero(titulo.numero_protocolo_distribuido, 10),
        F.texto(titulo.cedente.presence || titulo.apresentante&.nome, 45),
        "1",
        F.texto(titulo.endereco_devedor, 50),
        F.texto(titulo.cep_devedor, 8),
        titulo.efeito_falencia ? "F" : " "
      ].join
    end

    def linha_solidario(titulo, solidario, posicao)
      devedor = solidario.devedor
      [
        F.texto(devedor.tipo_documento, 4),
        F.texto(devedor.cpf_cnpj, 14),
        F.texto(titulo.tipo_titulo&.abreviatura, 3),
        F.texto(titulo.numero_titulo, 15),
        F.data(titulo.data_vencimento),
        F.data(titulo.data_recebimento),
        F.moeda(titulo.valor, 14),
        F.data(titulo.data_distribuicao),
        F.texto(titulo.cartorio&.codigo_legado, 1),
        F.texto(titulo.apresentante&.codigo_legado, 6),
        F.texto(titulo.apresentante&.nome, 45),
        F.texto(devedor.nome, 50),
        F.texto(titulo.oficio_distribuidor&.codigo_legado, 1),
        F.texto(titulo.status, 2),
        F.texto(titulo.remessa&.banco&.codigo_legado, 3),
        F.texto(titulo.codigo_agencia, 7),
        F.numero(titulo.numero_protocolo_distribuido, 10),
        F.texto(titulo.cedente.presence || titulo.apresentante&.nome, 45),
        posicao.to_s,
        F.texto(devedor.endereco, 50),
        F.texto(devedor.cep, 8),
        titulo.efeito_falencia ? "F" : " "
      ].join
    end
  end
end
