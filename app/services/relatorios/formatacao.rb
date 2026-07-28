module Relatorios
  # Helpers de formatação de exibição compartilhados entre os serviços de relatório — evita
  # repetir a mesma formatação de moeda/data em cada um.
  module Formatacao
    module_function

    def moeda(valor)
      ActiveSupport::NumberHelper.number_to_currency(valor, unit: "R$ ", separator: ",", delimiter: ".")
    end

    def data(valor)
      valor&.strftime("%d/%m/%Y")
    end
  end
end
