module RemessaImportacao
  # Leitura de campos por posição de byte (1-based, como no VB6 Mid()),
  # para as três variantes de registro de um arquivo de remessa de layout
  # fixo (~600 bytes/linha): header, detalhe e trailer.
  module Registro
    def initialize(linha)
      @linha = linha.to_s
    end

    def tipo_registro
      campo(1, 1)
    end

    def codigo_banco
      campo(2, 3)
    end

    private

    def campo(inicio, tamanho)
      @linha[inicio - 1, tamanho].to_s
    end

    def campo_strip(inicio, tamanho)
      campo(inicio, tamanho).strip
    end
  end
end
