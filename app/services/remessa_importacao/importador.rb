module RemessaImportacao
  # Importa um arquivo de remessa de layout fixo (~600 bytes/linha),
  # replicando as validações de arquivo inteiro e as críticas por título do
  # legado (frmImpTitulos.frm), mas gravando no schema novo e normalizado.
  #
  # Divergências propositais em relação ao legado (ver docs/ANALISE_MIGRACAO.md):
  # - título irregular por espécie não cadastrada fica com tipo_titulo_id nulo
  #   em vez de tipo_tit='*' (sem FK real para apontar);
  # - protocolo_original não é mais preenchido aqui (irrelevante para títulos
  #   novos — só serve para proveniência de dados vindos do legado via ETL);
  # - devedor.cpf_cnpj preserva zeros à esquerda (o legado convertia para
  #   Double em alguns pontos, um bug que não replicamos).
  class Importador
    # Código de apresentante isento da crítica de praça/cidade (ver
    # frmImpTitulos.frm — nenhuma documentação além do código mágico "073").
    APRESENTANTE_ISENTO_PRACA = "073".freeze

    def initialize(caminho_arquivo, nome_arquivo: nil)
      @caminho_arquivo = caminho_arquivo
      @nome_arquivo = nome_arquivo || File.basename(caminho_arquivo)
      @cidade_sede = Rails.application.config.x.remessa.cidade_sede.to_s.upcase
    end

    def importar
      linhas = ler_linhas

      validar_ja_importado!
      validar_caracteres!(linhas)
      validar_sequencia!(linhas)

      header = Header.new(linhas.first)
      raise ErroArquivo, "Registro header esperado na primeira linha." unless header.valido?

      banco = localizar_banco!(header.codigo_banco)
      apresentante = localizar_apresentante!(banco)

      detalhes_linhas = linhas[1..-2]
      contadores = validar_estrutura_detalhes!(detalhes_linhas, header)

      trailer = Trailer.new(linhas.last)
      validar_trailer!(trailer, header, contadores)

      gravar!(header, detalhes_linhas, contadores, banco, apresentante)
    rescue ErroArquivo => e
      registrar_falha(e)
      raise
    end

    private

    def ler_linhas
      File.readlines(@caminho_arquivo, encoding: "ISO-8859-1:UTF-8", chomp: true)
    end

    def validar_ja_importado!
      return unless Remessa.exists?(nome_arquivo: @nome_arquivo)

      raise ErroArquivo, "Este arquivo de remessa já foi importado. Para importá-lo novamente, cancele a importação anterior."
    end

    def validar_caracteres!(linhas)
      linhas.each_with_index do |linha, indice|
        next unless linha.each_char.any? { |c| c.ord < 32 }

        raise ErroArquivo, "Caractere especial detectado na linha #{indice + 1}."
      end
    end

    def validar_sequencia!(linhas)
      linhas.each_with_index do |linha, indice|
        numero_linha = indice + 1
        sequencial = linha[596, 4].to_i
        next if sequencial == numero_linha

        raise ErroArquivo, "Sequência de linhas incorreta, linha #{numero_linha}."
      end
    end

    def localizar_banco!(codigo_banco)
      Banco.find_by(codigo_legado: codigo_banco) ||
        Banco.find_by(codigo_alfa: codigo_banco) ||
        (raise ErroArquivo, "Apresentante/Banco não cadastrado com o código #{codigo_banco}.")
    end

    def localizar_apresentante!(banco)
      banco.apresentante || (raise ErroArquivo, "Banco sem apresentante definido (código CD2); importação não pode continuar.")
    end

    def validar_estrutura_detalhes!(detalhes_linhas, header)
      contadores = { registros_transacao: 0, titulos: 0, indicacoes: 0, originais: 0 }

      detalhes_linhas.each_with_index do |linha, indice|
        raise ErroArquivo, "Registro de transação esperado na linha #{indice + 2}." unless linha[0, 1] == "1"
        unless linha[1, 3] == header.codigo_banco
          raise ErroArquivo, "Divergência quanto ao código do portador (transação, linha #{indice + 2})."
        end

        detalhe = Detalhe.new(linha)
        contadores[:registros_transacao] += 1
        next unless detalhe.devedor_principal?

        contadores[:titulos] += 1
        contadores[detalhe.indicacao? ? :indicacoes : :originais] += 1
      end

      raise ErroArquivo, "Divergência na quantidade de títulos." if contadores[:titulos] != header.quantidade_titulos
      raise ErroArquivo, "Divergência na quantidade de indicações." if contadores[:indicacoes] != header.quantidade_indicacoes
      raise ErroArquivo, "Divergência na quantidade de originais." if contadores[:originais] != header.quantidade_originais

      contadores
    end

    def validar_trailer!(trailer, header, contadores)
      raise ErroArquivo, "Registro trailer esperado na última linha." unless trailer.valido?
      raise ErroArquivo, "Divergência quanto ao código do portador (trailer)." unless trailer.codigo_banco == header.codigo_banco

      soma_esperada = contadores.values.sum
      return if trailer.soma_seguranca_quantidade == soma_esperada

      raise ErroArquivo, "Divergência no somatório de segurança da quantidade."
    end

    def gravar!(header, detalhes_linhas, contadores, banco, apresentante)
      remessa = nil

      ApplicationRecord.transaction do
        remessa = Remessa.create!(
          nome_arquivo: @nome_arquivo,
          banco: banco,
          apresentante: apresentante,
          numero_remessa: header.numero_remessa,
          quantidade_registros_transacao: contadores[:registros_transacao],
          quantidade_titulos: contadores[:titulos],
          quantidade_indicacoes: contadores[:indicacoes],
          quantidade_originais: contadores[:originais],
          status: "importada"
        )
        remessa.arquivo.attach(
          io: File.open(@caminho_arquivo),
          filename: @nome_arquivo,
          content_type: "text/plain"
        )

        titulo_atual = nil
        detalhes_linhas.each do |linha|
          detalhe = Detalhe.new(linha)
          titulo_atual = if detalhe.devedor_principal?
            gravar_titulo_principal(detalhe, remessa, apresentante)
          else
            gravar_devedor_solidario(detalhe, titulo_atual)
            titulo_atual
          end
        end
      end

      remessa
    end

    def gravar_titulo_principal(detalhe, remessa, apresentante)
      devedor = localizar_ou_criar_devedor(detalhe)
      tipo_titulo = TipoTitulo.find_by(abreviatura: detalhe.especie)
      codigo_irregularidade, tipo_ocorrencia = avaliar_criticas(detalhe, tipo_titulo, apresentante)

      Titulo.create!(
        devedor: devedor,
        tipo_documento_devedor: detalhe.tipo_documento_devedor,
        cpf_cnpj_devedor: detalhe.documento_devedor,
        nome_devedor: detalhe.nome_devedor,
        endereco_devedor: detalhe.endereco_devedor,
        cep_devedor: detalhe.cep_devedor,
        cidade_devedor: detalhe.cidade_devedor,
        uf_devedor: detalhe.uf_devedor,
        tipo_titulo: tipo_titulo,
        numero_titulo: detalhe.numero_titulo,
        data_emissao: detalhe.data_emissao_invalida? ? nil : detalhe.data_emissao,
        data_vencimento: detalhe.data_vencimento,
        data_recebimento: Date.current,
        valor: detalhe.valor,
        apresentante: apresentante,
        cedente: detalhe.nome_cedente,
        nome_sacador: detalhe.nome_sacador,
        documento_sacador: detalhe.documento_sacador,
        endereco_sacador: detalhe.endereco_sacador,
        cep_sacador: detalhe.cep_sacador,
        cidade_sacador: detalhe.cidade_sacador,
        uf_sacador: detalhe.uf_sacador,
        status: "",
        efeito_falencia: detalhe.efeito_falencia?,
        irregularidade: codigo_irregularidade && Irregularidade.find_by(codigo: codigo_irregularidade),
        tipo_ocorrencia: tipo_ocorrencia,
        remessa: remessa
      )
    end

    def gravar_devedor_solidario(detalhe, titulo_atual)
      devedor = localizar_ou_criar_devedor(detalhe)
      codigo_irregularidade, = avaliar_criticas(detalhe, TipoTitulo.find_by(abreviatura: detalhe.especie), titulo_atual&.apresentante)

      DevedorSolidario.create!(
        titulo: titulo_atual,
        devedor: devedor,
        nosso_numero: detalhe.nosso_numero,
        especie: detalhe.especie
      )

      return unless titulo_atual && codigo_irregularidade

      titulo_atual.update!(
        irregularidade: Irregularidade.find_by(codigo: codigo_irregularidade),
        tipo_ocorrencia: "5"
      )
    end

    def localizar_ou_criar_devedor(detalhe)
      Devedor.find_or_create_by!(
        tipo_documento: detalhe.tipo_documento_devedor,
        cpf_cnpj: detalhe.documento_devedor
      ) do |devedor|
        devedor.nome = detalhe.nome_devedor
        devedor.endereco = detalhe.endereco_devedor_cadastro
        devedor.bairro = detalhe.bairro_devedor
        devedor.cep = detalhe.cep_devedor
        devedor.observacao = "inserido na importação do título"
      end
    end

    # Replica, na mesma ordem, as críticas de frmImpTitulos.frm#Criticas.
    # Como no legado, a última crítica que falhar é a que "vale" (não é uma
    # lista de erros — só o último código sobrescrito é gravado).
    def avaliar_criticas(detalhe, tipo_titulo, apresentante)
      codigo = nil

      codigo = 21 if tipo_titulo.nil?
      codigo = 7 if documento_devedor_invalido?(detalhe)
      codigo = 10 if documento_sacador_invalido?(detalhe)
      codigo = 16 if detalhe.numero_titulo.blank?
      codigo = 6 if endereco_devedor_insuficiente?(detalhe)
      codigo = 50 if detalhe.data_emissao_invalida?
      codigo = 1 if detalhe.data_vencimento.nil?
      codigo = 1 if detalhe.data_vencimento && detalhe.data_vencimento > Date.current
      codigo = 1 if detalhe.data_emissao && detalhe.data_vencimento && detalhe.data_emissao > detalhe.data_vencimento
      codigo = 3 if detalhe.nome_devedor.present? && detalhe.nome_devedor == detalhe.nome_cedente
      codigo = 3 if detalhe.nome_devedor.present? && detalhe.nome_devedor == detalhe.nome_sacador
      codigo = 50 if detalhe.documento_devedor == "00000000000000"
      codigo = 7 if detalhe.documento_devedor.present? && detalhe.documento_devedor == detalhe.documento_sacador

      if detalhe.devedor_principal?
        isento = apresentante&.codigo_legado == APRESENTANTE_ISENTO_PRACA
        unless isento
          codigo = 15 if detalhe.praca_pagamento.upcase != @cidade_sede
          codigo = 15 if detalhe.cidade_devedor.upcase != @cidade_sede
        end
        codigo = 50 if detalhe.tipo_documento_devedor == "CPF" && detalhe.efeito_falencia?
      end

      [ codigo, codigo ? "5" : "" ]
    end

    def documento_devedor_invalido?(detalhe)
      case detalhe.tipo_documento_devedor
      when "CNPJ" then !CNPJ.valid?(detalhe.documento_devedor)
      when "CPF" then !CPF.valid?(detalhe.documento_devedor.rjust(14, "0").last(11))
      else false
      end
    end

    def documento_sacador_invalido?(detalhe)
      doc = detalhe.documento_sacador
      if doc.match?(/\A\d+\z/)
        !(CPF.valid?(doc.rjust(14, "0").last(11)) || CNPJ.valid?(doc))
      else
        !CNPJ.valid?(doc)
      end
    end

    def endereco_devedor_insuficiente?(detalhe)
      endereco = detalhe.endereco_devedor
      return true if endereco.blank?
      return true if endereco.length < 5

      numero_presente = endereco.match?(/\d/) || endereco.match?(/S\/?N|S\?N/i)
      !numero_presente
    end

    def registrar_falha(erro)
      return if Remessa.exists?(nome_arquivo: @nome_arquivo)

      Remessa.create!(nome_arquivo: @nome_arquivo, status: "com_erro", mensagem_erro: erro.message)
    rescue ActiveRecord::RecordInvalid
      nil
    end
  end
end
