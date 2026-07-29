require "test_helper"

module Etl
  class ImportadorOficiosDistribuidoresTest < ActiveSupport::TestCase
    setup do
      ActiveRecord::Base.connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS public.cad_distribuidor (
          dis_cartorio varchar(40), dis_id char(1), blivre boolean
        )
      SQL
      ActiveRecord::Base.connection.execute("DELETE FROM public.cad_distribuidor")
    end

    teardown do
      ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS public.cad_distribuidor")
    end

    test "importa ofícios distribuidores" do
      inserir(id: "1", nome: "Ofício Um")
      inserir(id: "2", nome: "Ofício Dois")

      resultado = ImportadorOficiosDistribuidores.new.importar!

      assert_equal %w[1 2], resultado.criados.sort
      assert_equal "Ofício Um", OficioDistribuidor.find_by!(codigo_legado: "1").nome
    end

    test "é idempotente" do
      inserir(id: "1", nome: "Ofício Um")
      ImportadorOficiosDistribuidores.new.importar!

      resultado = ImportadorOficiosDistribuidores.new.importar!

      assert_empty resultado.criados
      assert_equal 1, resultado.ignorados
    end

    private

    def inserir(id:, nome:)
      ActiveRecord::Base.connection.execute(<<~SQL)
        INSERT INTO public.cad_distribuidor (dis_id, dis_cartorio, blivre) VALUES ('#{id}', '#{nome}', true)
      SQL
    end
  end
end
