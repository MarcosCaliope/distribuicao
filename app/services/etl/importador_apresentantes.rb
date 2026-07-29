module Etl
  # Importa apresentantes de public.cad_apresenta (legado) → Apresentante. Idempotente.
  # convenio: dado real tem valores fora de Apresentante::CONVENIOS (ex. "E", "|", vazio) —
  # fica nil quando não bate com C/I/B, o model já permite isso (allow_nil: true).
  class ImportadorApresentantes
    Resultado = Struct.new(:criados, :ignorados, :falhas, keyword_init: true)

    def importar!
      criados = []
      ignorados = 0
      falhas = []

      linhas_legado.each do |linha|
        codigo = linha["codigo"].to_s.strip
        nome = linha["nome"].to_s.strip
        next if codigo.blank? || nome.blank?

        if Apresentante.exists?(codigo_legado: codigo)
          ignorados += 1
          next
        end

        Apresentante.create!(
          codigo_legado: codigo,
          nome: nome,
          endereco: linha["endereco"].to_s.strip.presence,
          telefone: linha["fone"].to_s.strip.presence,
          contato: linha["contato"].to_s.strip.presence,
          agencia: linha["agencia"].to_s.strip.presence,
          tipo: linha["tipo"].to_s.strip.presence,
          convenio: convenio_valido(linha["convenio"]),
          custa_antecipada: linha["scustaantecipada"].to_s.strip == "S"
        )
        criados << codigo
      rescue ActiveRecord::RecordInvalid => e
        falhas << [ codigo, e.message ]
      end

      Resultado.new(criados: criados, ignorados: ignorados, falhas: falhas)
    end

    private

    def convenio_valido(valor)
      valor = valor.to_s.strip
      Apresentante::CONVENIOS.include?(valor) ? valor : nil
    end

    def linhas_legado
      ActiveRecord::Base.connection.select_all(<<~SQL)
        SELECT codigo, nome, endereco, fone, contato, agencia, tipo, convenio, scustaantecipada
        FROM public.cad_apresenta
      SQL
    end
  end
end
