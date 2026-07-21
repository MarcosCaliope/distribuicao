module RemessaImportacao
  class Detalhe
    include Registro

    ESPECIES_INDICACAO = %w[DMI DRI CBI].freeze

    def nome_cedente
      campo_strip(20, 45)
    end

    def nome_sacador
      campo_strip(65, 45)
    end

    def documento_sacador
      campo_strip(110, 14)
    end

    def endereco_sacador
      campo_strip(124, 45)
    end

    def cep_sacador
      campo_strip(169, 8)
    end

    def cidade_sacador
      campo_strip(177, 20)
    end

    def uf_sacador
      campo_strip(197, 2)
    end

    def nosso_numero
      campo_strip(199, 15)
    end

    def especie
      campo_strip(214, 3)
    end

    def indicacao?
      ESPECIES_INDICACAO.include?(especie)
    end

    def numero_titulo
      campo_strip(217, 11)
    end

    def data_emissao
      parse_data(campo(228, 8))
    end

    def data_emissao_invalida?
      data_emissao.nil? || data_emissao < Date.new(1900, 1, 1)
    end

    def data_vencimento
      case campo(236, 8)
      when "99999999" then data_emissao
      when "99990001" then data_emissao && data_emissao + 1
      when "99990030" then data_emissao && data_emissao + 30
      else parse_data(campo(236, 8))
      end
    end

    # Valor do título, já convertido de centavos para reais.
    def valor
      Rational(campo(247, 14).to_i, 100).to_f
    end

    # Valor usado apenas no somatório de segurança do trailer — no legado
    # este campo (byte 261) é lido separadamente do valor gravado no título
    # (byte 247); mantemos os dois por fidelidade ao arquivo original.
    def valor_checksum_centavos
      campo(261, 14).to_i
    end

    def praca_pagamento
      campo_strip(275, 20)
    end

    def devedor_principal?
      campo(297, 1) == "1"
    end

    def nome_devedor
      campo_strip(298, 45)
    end

    def tipo_documento_devedor
      case campo(343, 3)
      when "001" then "CNPJ"
      when "002" then "CPF"
      else "CI"
      end
    end

    def documento_devedor
      campo_strip(346, 14)
    end

    # Snapshot completo (45 posições) para o título — cad_titulos.senddevedor.
    def endereco_devedor
      campo_strip(371, 45)
    end

    # Truncado a 35 posições para o cadastro do devedor — mesmo limite de
    # cad_devedor.endereco no legado.
    def endereco_devedor_cadastro
      endereco_devedor.first(35)
    end

    def cep_devedor
      campo_strip(416, 8)
    end

    def cidade_devedor
      campo_strip(424, 20)
    end

    def uf_devedor
      campo_strip(444, 2)
    end

    def bairro_devedor
      campo_strip(488, 20)
    end

    def efeito_falencia?
      campo(566, 1) == "F"
    end

    def numero_sequencial
      campo(597, 4).to_i
    end

    private

    def parse_data(ddmmyyyy)
      Date.strptime(ddmmyyyy, "%d%m%Y")
    rescue ArgumentError, TypeError
      nil
    end
  end
end
