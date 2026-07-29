require "test_helper"

module Etl
  class ValidadorReplayHistoricoTest < ActiveSupport::TestCase
    ARQUIVO_REAL = Rails.root.join("test/fixtures/files/remessas/banco_brasil_valida.txt")

    setup do
      ActiveRecord::Base.connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS public.tblremessas (
          codapr varchar(6), datarem date, isql integer, situacao varchar(2),
          icodirreg integer, tipo_tit varchar(2), snomearquivotexto varchar(50), sregistro varchar(650)
        )
      SQL
      ActiveRecord::Base.connection.execute("DELETE FROM public.tblremessas")

      # Mesmo setup de test/services/remessa_importacao/importador_test.rb — o arquivo real
      # espera esses cadastros pra importar com sucesso.
      @apresentante = Apresentante.create!(codigo_legado: "001", nome: "Banco do Brasil", convenio: "B")
      Banco.create!(codigo_legado: "001", nome: "BANCO DO BRASIL SA", apresentante: @apresentante)
      TipoTitulo.create!(codigo_legado: "01", descricao: "Duplicata Mercantil por Indicação", abreviatura: "DMI")
    end

    teardown do
      ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS public.tblremessas")
    end

    test "sinaliza divergência só no título com espécie não cadastrada, não nos 14 regulares" do
      # CLAUDE.md documenta o arquivo real como "15 títulos: 14 DMI regulares + 1 DSI marcado
      # irregular por espécie não cadastrada" — um icodirreg=0 legado bate pros 14 regulares
      # (sem irregularidade computada) e diverge só pro DSI (codigo 21, espécie inválida).
      semear_arquivo("D0010706.211", data: Date.new(2026, 1, 5), icodirreg: 0)

      resultado = ValidadorReplayHistorico.new(data_inicio: Date.new(2026, 1, 1), data_fim: Date.new(2026, 1, 10)).validar!

      assert_equal 1, resultado.arquivos_processados
      assert_empty resultado.arquivos_com_erro
      assert_equal 15, resultado.titulos_comparados
      assert_equal 14, resultado.titulos_batendo
      assert_equal 1, resultado.mismatches.size
      assert_not_equal 0, resultado.mismatches.first[:irregularidade_obtida]
    end

    test "não persiste nada, mesmo quando o arquivo importa com sucesso" do
      semear_arquivo("D0010706.211", data: Date.new(2026, 1, 5), icodirreg: 0)

      ValidadorReplayHistorico.new(data_inicio: Date.new(2026, 1, 1), data_fim: Date.new(2026, 1, 10)).validar!

      assert_equal 0, Titulo.count
      assert_equal 0, Remessa.count
      assert_equal 0, Devedor.count
    end

    test "um arquivo malformado conta como erro sem travar os demais" do
      semear_arquivo("D0010706.211", data: Date.new(2026, 1, 5), icodirreg: 0)
      inserir_linha(nome_arquivo: "quebrado.txt", data: Date.new(2026, 1, 5), sregistro: "0LIXO", icodirreg: 0)

      resultado = ValidadorReplayHistorico.new(data_inicio: Date.new(2026, 1, 1), data_fim: Date.new(2026, 1, 10)).validar!

      assert_equal 1, resultado.arquivos_processados
      assert_equal 1, resultado.arquivos_com_erro.size
      assert_equal "quebrado.txt", resultado.arquivos_com_erro.first.first
      assert_equal 15, resultado.titulos_comparados
    end

    test "respeita o intervalo de datas" do
      semear_arquivo("D0010706.211", data: Date.new(2025, 1, 5), icodirreg: 0)

      resultado = ValidadorReplayHistorico.new(data_inicio: Date.new(2026, 1, 1), data_fim: Date.new(2026, 1, 10)).validar!

      assert_equal 0, resultado.arquivos_processados
      assert_equal 0, resultado.titulos_comparados
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
