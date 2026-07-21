module RemessaImportacao
  class Trailer
    include Registro

    def soma_seguranca_quantidade
      campo(53, 5).to_i
    end

    def soma_seguranca_valor_centavos
      campo(58, 18).to_i
    end

    def valido?
      tipo_registro == "9"
    end
  end
end
