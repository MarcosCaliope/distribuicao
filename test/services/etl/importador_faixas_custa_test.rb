require "test_helper"

module Etl
  class ImportadorFaixasCustaTest < ActiveSupport::TestCase
    setup do
      ActiveRecord::Base.connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS public.cad_faixas (
          tipo char(1), valor double precision, num_cart smallint, qtd_dia double precision,
          climiteinferior double precision, climitesuperior double precision, isequencial integer
        )
      SQL
      ActiveRecord::Base.connection.execute("DELETE FROM public.cad_faixas")
    end

    teardown do
      ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS public.cad_faixas")
    end

    test "importa faixa de custas" do
      inserir(sequencial: 1, tipo: "A", inferior: 0.01, superior: 14.20)

      resultado = ImportadorFaixasCusta.new.importar!

      assert_equal [ 1 ], resultado.criados
      faixa = FaixaCusta.find_by!(sequencial: 1)
      assert_equal "A", faixa.tipo
      assert_equal 0.01, faixa.limite_inferior
      assert_equal 14.20, faixa.limite_superior
    end

    test "é idempotente" do
      inserir(sequencial: 1, tipo: "A", inferior: 0.01, superior: 14.20)
      ImportadorFaixasCusta.new.importar!

      resultado = ImportadorFaixasCusta.new.importar!

      assert_empty resultado.criados
      assert_equal 1, resultado.ignorados
    end

    private

    def inserir(sequencial:, tipo:, inferior:, superior:)
      ActiveRecord::Base.connection.execute(<<~SQL)
        INSERT INTO public.cad_faixas (isequencial, tipo, climiteinferior, climitesuperior)
        VALUES (#{sequencial}, '#{tipo}', #{inferior}, #{superior})
      SQL
    end
  end
end
