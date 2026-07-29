module Etl
  # Suite de validação (não backfill — ver docs/ANALISE_MIGRACAO.md, itens 17-18): reconstrói
  # arquivos de remessa históricos a partir de public.tblremessas.sregistro num intervalo de
  # datarem, roda cada um pelo RemessaImportacao::Importador de verdade dentro de uma
  # transação sempre desfeita, e compara a irregularidade computada contra icodirreg (gravado
  # pela própria lógica de crítica do legado pra aquela linha). Não grava nenhum título.
  class ValidadorReplayHistorico
    Resultado = Struct.new(
      :arquivos_processados, :arquivos_com_erro, :titulos_comparados, :titulos_batendo, :mismatches,
      keyword_init: true
    )
    LIMITE_AMOSTRA_MISMATCH = 20

    def initialize(data_inicio:, data_fim:)
      @data_inicio = data_inicio
      @data_fim = data_fim
    end

    def validar!
      arquivos_processados = 0
      arquivos_com_erro = []
      titulos_comparados = 0
      titulos_batendo = 0
      mismatches = []

      nomes_arquivo.each do |nome_arquivo|
        resultado = processar_arquivo(nome_arquivo)

        if resultado[:erro]
          arquivos_com_erro << [ nome_arquivo, resultado[:erro] ]
          next
        end

        arquivos_processados += 1
        resultado[:comparacoes].each do |comparacao|
          titulos_comparados += 1
          if comparacao[:bate]
            titulos_batendo += 1
          elsif mismatches.size < LIMITE_AMOSTRA_MISMATCH
            mismatches << comparacao
          end
        end
      end

      Resultado.new(
        arquivos_processados: arquivos_processados, arquivos_com_erro: arquivos_com_erro,
        titulos_comparados: titulos_comparados, titulos_batendo: titulos_batendo, mismatches: mismatches
      )
    end

    private

    def nomes_arquivo
      sql = ActiveRecord::Base.sanitize_sql_array([
        "SELECT DISTINCT snomearquivotexto FROM public.tblremessas WHERE datarem BETWEEN ? AND ?",
        @data_inicio, @data_fim
      ])
      ActiveRecord::Base.connection.select_all(sql).to_a.map { |linha| linha["snomearquivotexto"] }
    end

    def linhas_do_arquivo(nome_arquivo)
      sql = ActiveRecord::Base.sanitize_sql_array([
        "SELECT sregistro, icodirreg, situacao FROM public.tblremessas WHERE snomearquivotexto = ?",
        nome_arquivo
      ])
      ActiveRecord::Base.connection.select_all(sql).to_a
    end

    def processar_arquivo(nome_arquivo)
      principais = linhas_do_arquivo(nome_arquivo)
        .select { |linha| principal?(linha["sregistro"]) }
        .sort_by { |linha| RemessaImportacao::Detalhe.new(linha["sregistro"]).numero_sequencial }

      conteudo = Etl::ReconstrutorRemessa.new.reconstruir(nome_arquivo)
      return { erro: "sem linhas reconstruíveis" } if conteudo.nil?

      titulos_criados, erro = importar_e_desfazer(nome_arquivo, conteudo)
      return { erro: erro } if erro

      comparacoes = principais.zip(titulos_criados).filter_map do |linha_legado, titulo|
        next if linha_legado.nil? || titulo.nil?

        comparar(nome_arquivo, linha_legado, titulo)
      end

      { comparacoes: comparacoes }
    end

    # Roda o pipeline de import de verdade, sem tocar em nada — a transação é sempre desfeita,
    # com sucesso ou com erro.
    def importar_e_desfazer(nome_arquivo, conteudo)
      titulos_criados = nil
      erro = nil

      ApplicationRecord.transaction do
        Tempfile.create([ "etl_replay", ".txt" ]) do |arquivo|
          arquivo.write(conteudo)
          arquivo.flush
          remessa = RemessaImportacao::Importador.new(
            arquivo.path, nome_arquivo: "#{nome_arquivo}-replay-#{SecureRandom.hex(4)}"
          ).importar
          titulos_criados = remessa.titulos.order(:id).to_a
        end
      rescue => e
        erro = e.message
      ensure
        raise ActiveRecord::Rollback
      end

      [ titulos_criados, erro ]
    end

    def principal?(sregistro)
      sregistro[0, 1] == "1" && RemessaImportacao::Detalhe.new(sregistro).devedor_principal?
    end

    def comparar(nome_arquivo, linha_legado, titulo)
      esperado = linha_legado["icodirreg"].to_i
      obtido = titulo.irregularidade&.codigo.to_i
      {
        arquivo: nome_arquivo,
        protocolo: titulo.protocolo_original || titulo.numero_titulo,
        irregularidade_esperada: esperado,
        irregularidade_obtida: obtido,
        bate: esperado == obtido
      }
    end
  end
end
