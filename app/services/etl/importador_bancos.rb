module Etl
  # Importa bancos/apresentantes-pagadores de public.cad_bancos (legado) → Banco. Idempotente.
  #
  # Mapeamentos não óbvios, verificados contra dado real antes de escrever isso (ver
  # docs/ANALISE_MIGRACAO.md):
  # - vcusta (varchar numérico zero-padded, ex. "0000000610") → valor_custa: tratado como
  #   centavos, mesma convenção usada em todo o resto do app pra campos monetários de largura
  #   fixa (ver Exportacao::FormatoFixo).
  # - bc_proce NÃO é importado: os valores reais ("0"/"1"/"3"/branco/nulo) não batem com um
  #   flag booleano simples e não há fonte que confirme o que cada código significa — mapear
  #   isso pra `processa` seria inventar um significado. `processa` fica no default do model.
  # - codalfa em branco (`"      "`, só espaços) vira nil, não string vazia — `codigo_alfa` tem
  #   índice único, e várias linhas legadas têm codalfa inteiramente em branco.
  # - "to"/ebanco não são importados: não existe coluna equivalente em Banco hoje.
  class ImportadorBancos
    Resultado = Struct.new(:criados, :ignorados, :falhas, keyword_init: true)

    def importar!
      criados = []
      ignorados = 0
      falhas = []

      linhas_legado.each do |linha|
        codigo = linha["codigo"].to_s.strip
        nome = linha["banco"].to_s.strip
        next if codigo.blank? || nome.blank?

        if Banco.exists?(codigo_legado: codigo)
          ignorados += 1
          next
        end

        Banco.create!(
          codigo_legado: codigo,
          nome: nome,
          codigo_alfa: linha["codalfa"].to_s.strip.presence,
          valor_custa: centavos_para_reais(linha["vcusta"]),
          gera_remessa_cartorio: ActiveModel::Type::Boolean.new.cast(linha["bngera"]),
          sequencia_confirmacao: linha["iseqconf"],
          email: linha["email"].to_s.strip.presence
        )
        criados << codigo
      rescue ActiveRecord::RecordInvalid => e
        falhas << [ codigo, e.message ]
      end

      Resultado.new(criados: criados, ignorados: ignorados, falhas: falhas)
    end

    private

    def centavos_para_reais(valor)
      digitos = valor.to_s.strip
      return nil if digitos.blank?

      digitos.to_i / 100.0
    end

    def linhas_legado
      ActiveRecord::Base.connection.select_all(<<~SQL)
        SELECT codigo, banco, codalfa, vcusta, bngera, iseqconf, email FROM public.cad_bancos
      SQL
    end
  end
end
