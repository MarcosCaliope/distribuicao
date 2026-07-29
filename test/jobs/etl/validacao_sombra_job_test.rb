require "test_helper"

module Etl
  class ValidacaoSombraJobTest < ActiveJob::TestCase
    ARQUIVO_REAL = Rails.root.join("test/fixtures/files/remessas/banco_brasil_valida.txt")

    setup do
      ActiveRecord::Base.connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS public.tblremessas (
          codapr varchar(6), datarem date, isql integer, situacao varchar(2),
          icodirreg integer, tipo_tit varchar(2), snomearquivotexto varchar(50), sregistro varchar(650)
        )
      SQL
      ActiveRecord::Base.connection.execute("DELETE FROM public.tblremessas")

      @apresentante = Apresentante.create!(codigo_legado: "001", nome: "Banco do Brasil", convenio: "B")
      Banco.create!(codigo_legado: "001", nome: "BANCO DO BRASIL SA", apresentante: @apresentante)
      TipoTitulo.create!(codigo_legado: "01", descricao: "Duplicata Mercantil por Indicação", abreviatura: "DMI")
    end

    teardown do
      ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS public.tblremessas")
    end

    test "persiste uma ValidacaoSombraExecucao com os contadores da comparação" do
      data = Date.new(2026, 1, 5)
      semear_arquivo("D0010706.211", data: data, icodirreg: 0)

      assert_difference -> { ValidacaoSombraExecucao.count }, 1 do
        ValidacaoSombraJob.perform_now(data: data)
      end

      execucao = ValidacaoSombraExecucao.last
      assert_equal data, execucao.data_inicio
      assert_equal data, execucao.data_fim
      assert_equal 1, execucao.arquivos_processados
      assert_empty execucao.arquivos_com_erro
      assert_equal 15, execucao.titulos_comparados
      assert_equal 14, execucao.titulos_batendo
      assert_equal 1, execucao.divergencias
      assert_equal 1, execucao.mismatches.size
    end

    test "não persiste título nenhum (validação continua sem gravar nada)" do
      data = Date.new(2026, 1, 5)
      semear_arquivo("D0010706.211", data: data, icodirreg: 0)

      ValidacaoSombraJob.perform_now(data: data)

      assert_equal 0, Titulo.count
      assert_equal 0, Remessa.count
    end

    private

    def semear_arquivo(nome_arquivo, data:, icodirreg:)
      linhas = File.read(ARQUIVO_REAL, encoding: Encoding::ISO_8859_1).encode(Encoding::UTF_8).split("\r\n")
      linhas.shuffle.each { |linha| inserir_linha(nome_arquivo: nome_arquivo, data: data, sregistro: linha, icodirreg: icodirreg) }
    end

    def inserir_linha(nome_arquivo:, data:, sregistro:, icodirreg:)
      sql = "INSERT INTO public.tblremessas (snomearquivotexto, datarem, sregistro, icodirreg) VALUES (" \
            "#{quote(nome_arquivo)}, #{quote(data)}, #{quote(sregistro)}, #{icodirreg})"
      ActiveRecord::Base.connection.execute(sql)
    end

    def quote(valor)
      ActiveRecord::Base.connection.quote(valor)
    end
  end
end
