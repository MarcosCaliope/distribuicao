module RemessaImportacao
  class Header
    include Registro

    def numero_remessa
      campo_strip(62, 6)
    end

    def quantidade_registros_transacao
      campo(68, 4).to_i
    end

    def quantidade_titulos
      campo(72, 4).to_i
    end

    def quantidade_indicacoes
      campo(76, 4).to_i
    end

    def quantidade_originais
      campo(80, 4).to_i
    end

    def valido?
      tipo_registro == "0"
    end
  end
end
