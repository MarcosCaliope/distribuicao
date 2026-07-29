module Etl
  # Importa faixas de custas de public.cad_faixas (legado) → FaixaCusta. Idempotente
  # (chave natural: sequencial). Só 6 linhas em produção (A-F), já usadas como referência real
  # desde a Etapa 3 (Distribuicao::SorteioCartorio).
  class ImportadorFaixasCusta
    Resultado = Struct.new(:criados, :ignorados, :falhas, keyword_init: true)

    def importar!
      criados = []
      ignorados = 0
      falhas = []

      linhas_legado.each do |linha|
        sequencial = linha["isequencial"]
        next if sequencial.blank?

        if FaixaCusta.exists?(sequencial: sequencial)
          ignorados += 1
          next
        end

        FaixaCusta.create!(
          sequencial: sequencial,
          tipo: linha["tipo"].to_s.strip,
          valor: linha["valor"],
          numero_cartorios: linha["num_cart"],
          quantidade_dia: linha["qtd_dia"],
          limite_inferior: linha["climiteinferior"],
          limite_superior: linha["climitesuperior"]
        )
        criados << sequencial
      rescue ActiveRecord::RecordInvalid => e
        falhas << [ sequencial, e.message ]
      end

      Resultado.new(criados: criados, ignorados: ignorados, falhas: falhas)
    end

    private

    def linhas_legado
      ActiveRecord::Base.connection.select_all(<<~SQL)
        SELECT isequencial, tipo, valor, num_cart, qtd_dia, climiteinferior, climitesuperior
        FROM public.cad_faixas
      SQL
    end
  end
end
