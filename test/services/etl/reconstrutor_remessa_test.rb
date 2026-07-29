require "test_helper"

module Etl
  class ReconstrutorRemessaTest < ActiveSupport::TestCase
    ARQUIVO_REAL = Rails.root.join("test/fixtures/files/remessas/banco_brasil_valida.txt")

    setup do
      ActiveRecord::Base.connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS public.tblremessas (
          codapr varchar(6), datarem date, isql integer, situacao varchar(2),
          icodirreg integer, tipo_tit varchar(2), snomearquivotexto varchar(50), sregistro varchar(650)
        )
      SQL
      ActiveRecord::Base.connection.execute("DELETE FROM public.tblremessas")
    end

    teardown do
      ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS public.tblremessas")
    end

    test "reconstrói um arquivo real linha a linha, na ordem certa, mesmo inseridas fora de ordem" do
      linhas = File.read(ARQUIVO_REAL, encoding: Encoding::ISO_8859_1).encode(Encoding::UTF_8).split("\r\n")
      # Compara contra as linhas originais unidas do mesmo jeito que a reconstrução une —
      # o arquivo fonte tem um CRLF final depois do trailer que dividir+juntar não preserva,
      # o que não importa pra quem consome (RemessaImportacao::Importador lê linha a linha).
      esperado = linhas.join("\r\n")

      linhas.shuffle.each { |linha| inserir(nome_arquivo: "D0010706.211", sregistro: linha) }

      reconstruido = ReconstrutorRemessa.new.reconstruir("D0010706.211")

      assert_equal esperado, reconstruido
    end

    test "retorna nil quando o arquivo não existe" do
      assert_nil ReconstrutorRemessa.new.reconstruir("arquivo_inexistente.txt")
    end

    private

    def inserir(nome_arquivo:, sregistro:)
      sql = "INSERT INTO public.tblremessas (snomearquivotexto, sregistro) VALUES (" \
            "#{ActiveRecord::Base.connection.quote(nome_arquivo)}, " \
            "#{ActiveRecord::Base.connection.quote(sregistro)})"
      ActiveRecord::Base.connection.execute(sql)
    end
  end
end
