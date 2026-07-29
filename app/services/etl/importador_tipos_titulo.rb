module Etl
  # Importa espécies de título de public.cad_tipostit (legado) → TipoTitulo. Idempotente.
  # Chave de upsert é codigo (→ codigo_legado), não abrevia: dado real tem abreviaturas
  # duplicadas sob códigos diferentes (ex. "CBI", "EC", "TM" cada uma aparece 2x) — como
  # TipoTitulo.abreviatura tem restrição de unicidade própria, a segunda ocorrência de cada
  # uma vai falhar a validação e cair em `falhas`, não travar o restante do lote.
  #
  # Diferente de Irregularidade (seedada de comentário de código-fonte VB6, não de tabela),
  # TipoTitulo não tinha fonte de dado nenhuma antes desta Etapa — lacuna real, não redundância.
  class ImportadorTiposTitulo
    Resultado = Struct.new(:criados, :ignorados, :falhas, keyword_init: true)

    def importar!
      criados = []
      ignorados = 0
      falhas = []

      linhas_legado.each do |linha|
        codigo = linha["codigo"].to_s.strip
        abreviatura = linha["abrevia"].to_s.strip
        next if codigo.blank? || abreviatura.blank?

        if TipoTitulo.exists?(codigo_legado: codigo)
          ignorados += 1
          next
        end

        TipoTitulo.create!(
          codigo_legado: codigo,
          abreviatura: abreviatura,
          descricao: linha["descricao"].to_s.strip.presence || abreviatura
        )
        criados << codigo
      rescue ActiveRecord::RecordInvalid => e
        falhas << [ codigo, e.message ]
      end

      Resultado.new(criados: criados, ignorados: ignorados, falhas: falhas)
    end

    private

    def linhas_legado
      ActiveRecord::Base.connection.select_all("SELECT codigo, descricao, abrevia FROM public.cad_tipostit")
    end
  end
end
