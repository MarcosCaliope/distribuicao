module RemessaImportacao
  # Falha estrutural do arquivo inteiro (não de um título específico) —
  # nenhum título é gravado quando isso é levantado.
  class ErroArquivo < StandardError
  end
end
