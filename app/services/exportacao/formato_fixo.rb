module Exportacao
  # Helpers de formatação de largura fixa, equivalentes a TrataString/TrataMoeda/TrataDuplo do
  # legado (BibCaracteres.cls). Compartilhados entre GeradorManifesto e GeradorRetorno para não
  # duplicar a lógica de padding entre os dois escritores.
  module FormatoFixo
    module_function

    # TrataString: alinhado à esquerda, espaços à direita; truncado se maior que o tamanho (o
    # legado quebra em runtime nesse caso — Space() com argumento negativo — não replicado).
    def texto(valor, tamanho)
      valor.to_s.strip[0, tamanho].to_s.ljust(tamanho)
    end

    # TrataDuplo: só dígitos, zero-padded à esquerda. Levanta em vez de truncar dígitos
    # significativos quando o valor não cabe — truncar um protocolo ou valor monetário
    # corromperia o número, diferente de truncar um texto.
    def numero(valor, tamanho)
      digitos = valor.to_s.gsub(/\D/, "")
      if digitos.length > tamanho
        raise ArgumentError, "#{valor.inspect} não cabe em #{tamanho} dígitos"
      end

      digitos.rjust(tamanho, "0")
    end

    # TrataMoeda: valor em reais -> centavos, zero-padded à esquerda.
    def moeda(valor, tamanho)
      centavos = valor.nil? ? 0 : (valor * 100).round
      numero(centavos, tamanho)
    end

    # Format(data, "ddmmyyyy"); branco quando nil (o legado quebra nesse caso — não replicado).
    def data(valor)
      valor ? valor.strftime("%d%m%Y") : " " * 8
    end
  end
end
