module Etl
  # Importa cartórios de public.cad_protesto (legado) → Cartorio. Idempotente — pula quem já
  # foi importado (chave natural: codigo_legado). ativa_sc_titulos → ativo: é a única flag de
  # atividade que cad_protesto tem, resolvendo a ambiguidade que as Etapas 4 e 5 deixaram em
  # aberto (ver docs/ANALISE_MIGRACAO.md, item 18). blivre não é importado — já documentado
  # como código morto/vestigial (item 7); o estado de rodízio é gerido pelo Rails a partir daqui
  # (VagaDistribuicao, ver Etapa 3).
  class ImportadorCartorios
    Resultado = Struct.new(:criados, :ignorados, :falhas, keyword_init: true)

    def importar!
      criados = []
      ignorados = 0
      falhas = []

      linhas_legado.each do |linha|
        codigo = linha["pro_id"].to_s.strip
        nome = linha["pro_cartorio"].to_s.strip
        next if codigo.blank? || nome.blank?

        if Cartorio.exists?(codigo_legado: codigo)
          ignorados += 1
          next
        end

        Cartorio.create!(
          codigo_legado: codigo,
          nome: nome,
          oficial: linha["pro_oficial"].to_s.strip.presence,
          telefone: linha["pro_fone"].to_s.strip.presence,
          email: linha["pro_email"].to_s.strip.presence,
          email_copia: linha["scopiaemail"].to_s.strip.presence,
          ativo: ActiveModel::Type::Boolean.new.cast(linha["ativa_sc_titulos"])
        )
        criados << codigo
      rescue ActiveRecord::RecordInvalid => e
        falhas << [ codigo, e.message ]
      end

      Resultado.new(criados: criados, ignorados: ignorados, falhas: falhas)
    end

    private

    def linhas_legado
      ActiveRecord::Base.connection.select_all(<<~SQL)
        SELECT pro_id, pro_cartorio, pro_oficial, pro_fone, pro_email, scopiaemail, ativa_sc_titulos
        FROM public.cad_protesto
      SQL
    end
  end
end
