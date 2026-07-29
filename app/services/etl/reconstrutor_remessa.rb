module Etl
  # Reconstrói um arquivo de remessa histórico a partir das linhas brutas gravadas em
  # public.tblremessas.sregistro (ver docs/ANALISE_MIGRACAO.md, item 17) — usado pela suite de
  # validação (Etl::ValidadorReplayHistorico), não por importação ao vivo.
  #
  # Ordenação: cada linha de detalhe já carrega sua própria posição no arquivo original
  # (numero_sequencial, bytes 597-600 — já exposto publicamente por
  # RemessaImportacao::Detalhe), então não precisa de nenhuma coluna externa de ordem. "0"
  # (header) < "1" (detalhe) < "9" (trailer) já ordena certo como string; dentro dos "1",
  # ordena pelo numero_sequencial de cada linha.
  class ReconstrutorRemessa
    def reconstruir(nome_arquivo)
      linhas = linhas_legado(nome_arquivo)
      return nil if linhas.empty?

      linhas.sort_by { |sregistro| chave_ordenacao(sregistro) }.join("\r\n")
    end

    private

    def chave_ordenacao(sregistro)
      tipo_registro = sregistro[0, 1]
      numero_sequencial = tipo_registro == "1" ? RemessaImportacao::Detalhe.new(sregistro).numero_sequencial : 0
      [ tipo_registro, numero_sequencial ]
    end

    def linhas_legado(nome_arquivo)
      sql = "SELECT sregistro FROM public.tblremessas WHERE snomearquivotexto = " \
            "#{ActiveRecord::Base.connection.quote(nome_arquivo)}"
      ActiveRecord::Base.connection.select_all(sql).to_a.map { |linha| linha["sregistro"] }
    end
  end
end
