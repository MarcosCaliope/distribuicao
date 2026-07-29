module Etl
  # Importa ofícios distribuidores de public.cad_distribuidor (legado) → OficioDistribuidor.
  # Idempotente. blivre não é importado — o rodízio (livre) é gerido pelo Rails a partir daqui
  # (Distribuicao::RodizioOficio, Etapa 3), começando sempre livre por padrão.
  class ImportadorOficiosDistribuidores
    Resultado = Struct.new(:criados, :ignorados, :falhas, keyword_init: true)

    def importar!
      criados = []
      ignorados = 0
      falhas = []

      linhas_legado.each do |linha|
        codigo = linha["dis_id"].to_s.strip
        nome = linha["dis_cartorio"].to_s.strip
        next if codigo.blank? || nome.blank?

        if OficioDistribuidor.exists?(codigo_legado: codigo)
          ignorados += 1
          next
        end

        OficioDistribuidor.create!(codigo_legado: codigo, nome: nome)
        criados << codigo
      rescue ActiveRecord::RecordInvalid => e
        falhas << [ codigo, e.message ]
      end

      Resultado.new(criados: criados, ignorados: ignorados, falhas: falhas)
    end

    private

    def linhas_legado
      ActiveRecord::Base.connection.select_all("SELECT dis_id, dis_cartorio FROM public.cad_distribuidor")
    end
  end
end
