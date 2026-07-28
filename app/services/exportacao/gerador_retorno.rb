module Exportacao
  # Gera o retorno por cartório+apresentante, replicando frmExportaTitulos.frm#GeraDetalhe do
  # legado (ver docs/ANALISE_MIGRACAO.md, Etapa 4). Reaproveita, campo a campo, os offsets já
  # estabelecidos por app/services/remessa_importacao/{header,detalhe,trailer}.rb — mas como
  # escritor, não leitor: não há como reabrir aquelas classes (elas fatiam uma `@linha`
  # existente, não constroem uma). Os offsets abaixo têm que ser mantidos em sincronia manual
  # com os daquelas classes; qualquer mudança lá precisa de conferência aqui também.
  #
  # O legado gera esse arquivo copiando a linha ORIGINAL importada (`tblremessas.sregistro`)
  # byte a byte e só sobrescrevendo um bloco de 42 bytes (446-487) com dado de ocorrência de
  # protesto. O Rails não guarda a linha bruta por título (só o arquivo inteiro anexado em
  # `Remessa`) — a linha aqui é reconstruída a partir das colunas de `Titulo`. Todo byte que o
  # parser de import (`Detalhe`) não lê tampouco tem de onde vir aqui — fica em branco,
  # documentado nos comentários abaixo, e não é uma omissão silenciosa.
  class GeradorRetorno
    F = FormatoFixo
    TAMANHO_LINHA = 600
    MAX_CODEVEDORES = 9

    def initialize(data: Date.current)
      @data = data
    end

    def gerar
      Cartorio.ativos.find_each.flat_map { |cartorio| gerar_para_cartorio(cartorio) }
    end

    private

    def gerar_para_cartorio(cartorio)
      apresentante_ids = titulos_elegiveis(cartorio).distinct.pluck(:apresentante_id).compact
      apresentante_ids.filter_map { |id| gerar_par(cartorio, Apresentante.find(id)) }
    end

    def titulos_elegiveis(cartorio)
      Titulo.pendentes_retorno
            .joins(remessa: :banco)
            .where(data_distribuicao: @data, cartorio: cartorio)
            .where.not(tipo_titulo_id: nil)
            .where(bancos: { gera_remessa_cartorio: true })
    end

    def gerar_par(cartorio, apresentante)
      titulos = titulos_elegiveis(cartorio).where(apresentante: apresentante)
                                            .order(:numero_protocolo_distribuido).to_a
      return if titulos.empty?

      conteudo = +header(titulos)
      posicao = 0
      titulos.each do |titulo|
        linhas, posicao = linhas_do_titulo(titulo, posicao)
        conteudo << linhas
      end
      conteudo << trailer(titulos)

      retorno = nil
      ApplicationRecord.transaction do
        retorno = RetornoExportado.create!(
          cartorio: cartorio, apresentante: apresentante, data: @data,
          quantidade_titulos: titulos.size
        )
        retorno.arquivo.attach(
          io: StringIO.new(conteudo),
          filename: "retorno_#{cartorio.codigo_legado}_#{apresentante.codigo_legado}_" \
                    "#{@data.strftime('%Y%m%d')}.txt",
          content_type: "text/plain"
        )
        Titulo.where(id: titulos.map(&:id)).update_all(retorno_exportado_id: retorno.id)
      end
      Exportacao::EnvioRetornoJob.perform_later(retorno.id)
      retorno
    end

    def indicacao?(titulo)
      RemessaImportacao::Detalhe::ESPECIES_INDICACAO.include?(titulo.tipo_titulo&.abreviatura)
    end

    def header(titulos)
      indicacoes = titulos.count { |t| indicacao?(t) }
      registros = titulos.sum { |t| 1 + t.devedor_solidarios.size }
      linha = [
        "0",
        F.texto(titulos.first.remessa&.banco&.codigo_legado, 3),
        F.texto(nil, 57), # não modelado pelo import (bytes 5-61)
        F.texto(titulos.first.remessa&.numero_remessa, 6),
        F.numero(registros, 4),
        F.numero(titulos.size, 4),
        F.numero(indicacoes, 4),
        F.numero(titulos.size - indicacoes, 4),
        F.texto(nil, 517) # não modelado pelo import (bytes 84-600)
      ].join
      completar(linha) + "\r\n"
    end

    def trailer(titulos)
      registros = titulos.sum { |t| 1 + t.devedor_solidarios.size }
      centavos_totais = titulos.sum { |t| (t.valor * 100).round }
      linha = [
        "9",
        F.texto(titulos.first.remessa&.banco&.codigo_legado, 3),
        F.texto(nil, 48), # não modelado pelo import (bytes 5-52)
        F.numero(registros, 5),
        F.numero(centavos_totais, 18),
        F.texto(nil, 525) # não modelado pelo import (bytes 76-600)
      ].join
      completar(linha) + "\r\n"
    end

    def linhas_do_titulo(titulo, posicao)
      solidarios = titulo.devedor_solidarios.includes(:devedor).to_a
      if solidarios.size > MAX_CODEVEDORES - 1
        raise ArgumentError, "título #{titulo.id} tem mais de #{MAX_CODEVEDORES - 1} codevedores"
      end

      posicao += 1
      linhas = +linha_detalhe(titulo, posicao: posicao, principal: true, nome: titulo.nome_devedor,
                                       tipo_documento: titulo.tipo_documento_devedor,
                                       documento: titulo.cpf_cnpj_devedor,
                                       endereco: titulo.endereco_devedor,
                                       cep: titulo.cep_devedor, cidade: titulo.cidade_devedor,
                                       uf: titulo.uf_devedor)
      solidarios.each do |solidario|
        devedor = solidario.devedor
        posicao += 1
        linhas << linha_detalhe(titulo, posicao: posicao, principal: false, nome: devedor.nome,
                                         tipo_documento: devedor.tipo_documento,
                                         documento: devedor.cpf_cnpj, endereco: devedor.endereco,
                                         cep: devedor.cep, cidade: nil, uf: nil)
      end
      [ linhas, posicao ]
    end

    def linha_detalhe(titulo, posicao:, principal:, nome:, tipo_documento:, documento:, endereco:, cep:, cidade:, uf:)
      linha = [
        "1",
        F.texto(titulo.remessa&.banco&.codigo_legado, 3),
        F.texto(nil, 15), # não modelado pelo import (bytes 5-19)
        F.texto(titulo.cedente.presence, 45),
        F.texto(titulo.nome_sacador, 45),
        F.texto(titulo.documento_sacador, 14),
        F.texto(titulo.endereco_sacador, 45),
        F.texto(titulo.cep_sacador, 8),
        F.texto(titulo.cidade_sacador, 20),
        F.texto(titulo.uf_sacador, 2),
        F.texto(nil, 15), # nosso_numero: só existe hoje em DevedorSolidario, não em Titulo
        F.texto(titulo.tipo_titulo&.abreviatura, 3),
        F.texto(titulo.numero_titulo, 11),
        F.data(titulo.data_emissao),
        F.data(titulo.data_vencimento),
        F.texto(nil, 3), # não modelado pelo import (bytes 244-246)
        F.moeda(titulo.valor, 14),
        F.moeda(titulo.valor, 14), # soma de segurança: mesmo valor, nunca comparado no import
        F.texto(nil, 20), # praca_pagamento: lido no import mas não persistido em Titulo
        F.texto(nil, 2), # não modelado pelo import (bytes 295-296)
        principal ? "1" : "0",
        F.texto(nome, 45),
        F.texto(codigo_tipo_documento(tipo_documento), 3),
        F.texto(documento, 14),
        F.texto(nil, 11), # não modelado pelo import (bytes 360-370)
        F.texto(endereco, 45),
        F.texto(cep, 8),
        F.texto(cidade, 20),
        F.texto(uf, 2),
        bloco_ocorrencia(titulo),
        F.texto(nil, 20), # bairro_devedor: não existe em Titulo nem em Devedor
        F.texto(nil, 58), # não modelado pelo import (bytes 508-565)
        titulo.efeito_falencia ? "F" : " ",
        F.texto(nil, 30), # não modelado pelo import (bytes 567-596)
        F.numero(posicao, 4)
      ].join
      completar(linha) + "\r\n"
    end

    # Bloco específico do retorno (bytes 446-487, 42 bytes) — dado de ocorrência de protesto
    # que o import nunca lê. `custas`, `declaração do portador` e `data_ocorrencia` não têm
    # coluna nenhuma hoje (o app ainda não tem uma feature de acompanhamento de protesto) —
    # ficam em branco até essa etapa existir, ver docs/ANALISE_MIGRACAO.md.
    def bloco_ocorrencia(titulo)
      [
        F.texto(titulo.cartorio&.codigo_legado, 2),
        F.numero(titulo.numero_protocolo_distribuido, 10),
        F.texto(titulo.tipo_ocorrencia, 1),
        F.data(titulo.data_recebimento),
        F.texto(nil, 10), # custas: não modelado ainda
        F.texto(nil, 1),  # declaração do portador: não modelado ainda
        F.texto(nil, 8),  # data da ocorrência: não modelado ainda
        titulo.irregularidade ? F.numero(titulo.irregularidade.codigo, 2) : F.texto(nil, 2)
      ].join
    end

    # "CI" no import é um catch-all sem código original recuperável (ver
    # docs/ANALISE_MIGRACAO.md) — "003" é um placeholder, não um código real do banco.
    def codigo_tipo_documento(tipo_documento)
      case tipo_documento
      when "CNPJ" then "001"
      when "CPF" then "002"
      else "003"
      end
    end

    def completar(linha)
      linha.ljust(TAMANHO_LINHA)
    end
  end
end
