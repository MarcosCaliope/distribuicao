module Etl
  # Importa feriados de public.tblferiados (legado) → Feriado. Idempotente (chave natural: data).
  class ImportadorFeriados
    Resultado = Struct.new(:criados, :ignorados, :falhas, keyword_init: true)

    def importar!
      criados = []
      ignorados = 0
      falhas = []

      linhas_legado.each do |linha|
        data = linha["dtferiado"]
        next if data.blank?

        if Feriado.exists?(data: data)
          ignorados += 1
          next
        end

        Feriado.create!(data: data, descricao: linha["sdescricao"].to_s.strip.presence || "Feriado")
        criados << data.to_s
      rescue ActiveRecord::RecordInvalid => e
        falhas << [ data.to_s, e.message ]
      end

      Resultado.new(criados: criados, ignorados: ignorados, falhas: falhas)
    end

    private

    def linhas_legado
      ActiveRecord::Base.connection.select_all("SELECT dtferiado, sdescricao FROM public.tblferiados")
    end
  end
end
