require "test_helper"

module Etl
  class ImportadorFeriadosTest < ActiveSupport::TestCase
    setup do
      ActiveRecord::Base.connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS public.tblferiados (
          dtferiado date, sdescricao varchar(50)
        )
      SQL
      ActiveRecord::Base.connection.execute("DELETE FROM public.tblferiados")
    end

    teardown do
      ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS public.tblferiados")
    end

    test "importa feriado" do
      inserir(data: "2026-01-01", descricao: "Confraternização Universal")

      resultado = ImportadorFeriados.new.importar!

      assert_equal 1, resultado.criados.size
      feriado = Feriado.find_by!(data: Date.new(2026, 1, 1))
      assert_equal "Confraternização Universal", feriado.descricao
    end

    test "é idempotente" do
      inserir(data: "2026-01-01", descricao: "Confraternização Universal")
      ImportadorFeriados.new.importar!

      resultado = ImportadorFeriados.new.importar!

      assert_empty resultado.criados
      assert_equal 1, resultado.ignorados
    end

    private

    def inserir(data:, descricao:)
      ActiveRecord::Base.connection.execute(<<~SQL)
        INSERT INTO public.tblferiados (dtferiado, sdescricao) VALUES ('#{data}', '#{descricao}')
      SQL
    end
  end
end
