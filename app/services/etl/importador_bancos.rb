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
  # - cd2 → apresentante_id: é o mesmo "código CD2" citado em
  #   RemessaImportacao::Importador#localizar_apresentante!, resolvido contra
  #   Apresentante.codigo_legado. Sem match (dado real: ~70 dos 4831 bancos) fica nil — não é
  #   tratado como falha, só não linka. Bancos já importados sem apresentante_id são
  #   retroativamente linkados numa nova rodada (ver teste "backfilla apresentante_id"), então
  #   rodar a task de novo corrige o cadastro existente sem duplicar nada.
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

        apresentante_id = Apresentante.find_by(codigo_legado: linha["cd2"].to_s.strip.presence)&.id

        banco = Banco.find_by(codigo_legado: codigo)
        if banco
          banco.update!(apresentante_id: apresentante_id) if banco.apresentante_id.nil? && apresentante_id
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
          email: linha["email"].to_s.strip.presence,
          apresentante_id: apresentante_id
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
        SELECT codigo, banco, codalfa, vcusta, bngera, iseqconf, email, cd2 FROM public.cad_bancos
      SQL
    end
  end
end
