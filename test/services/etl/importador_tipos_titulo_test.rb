require "test_helper"

module Etl
  class ImportadorTiposTituloTest < ActiveSupport::TestCase
    setup do
      ActiveRecord::Base.connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS public.cad_tipostit (
          codigo varchar(2), descricao varchar(30), abrevia varchar(3)
        )
      SQL
      ActiveRecord::Base.connection.execute("DELETE FROM public.cad_tipostit")
    end

    teardown do
      ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS public.cad_tipostit")
    end

    test "importa tipos de título usando codigo como chave" do
      inserir(codigo: "1", descricao: "Duplicata", abrevia: "DMI")

      resultado = ImportadorTiposTitulo.new.importar!

      assert_equal [ "1" ], resultado.criados
      tipo = TipoTitulo.find_by!(codigo_legado: "1")
      assert_equal "DMI", tipo.abreviatura
      assert_equal "Duplicata", tipo.descricao
    end

    test "abreviatura duplicada sob código diferente vira falha, não trava o lote" do
      inserir(codigo: "1", descricao: "Duplicata", abrevia: "DMI")
      inserir(codigo: "2", descricao: "Outra Duplicata", abrevia: "DMI")
      inserir(codigo: "3", descricao: "Cheque", abrevia: "CH")

      resultado = ImportadorTiposTitulo.new.importar!

      assert_equal %w[1 3], resultado.criados.sort
      assert_equal 1, resultado.falhas.size
      assert_equal "2", resultado.falhas.first.first
    end

    test "é idempotente" do
      inserir(codigo: "1", descricao: "Duplicata", abrevia: "DMI")
      ImportadorTiposTitulo.new.importar!

      resultado = ImportadorTiposTitulo.new.importar!

      assert_empty resultado.criados
      assert_equal 1, resultado.ignorados
    end

    private

    def inserir(codigo:, descricao:, abrevia:)
      ActiveRecord::Base.connection.execute(<<~SQL)
        INSERT INTO public.cad_tipostit (codigo, descricao, abrevia) VALUES ('#{codigo}', '#{descricao}', '#{abrevia}')
      SQL
    end
  end
end
