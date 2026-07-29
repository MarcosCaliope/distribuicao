require "test_helper"

module Etl
  class ImportadorCartoriosTest < ActiveSupport::TestCase
    setup do
      ActiveRecord::Base.connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS public.cad_protesto (
          pro_id char(1), pro_cartorio varchar(40), pro_oficial varchar(40),
          pro_fone char(12), pro_email varchar(150), scopiaemail varchar(100),
          ativa_sc_titulos boolean
        )
      SQL
      ActiveRecord::Base.connection.execute("DELETE FROM public.cad_protesto")
    end

    teardown do
      ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS public.cad_protesto")
    end

    test "importa cartório ativo com ativa_sc_titulos mapeado para ativo" do
      inserir(id: "1", nome: "Cartório Um", ativo: true)
      inserir(id: "2", nome: "Cartório Dois", ativo: false)

      resultado = ImportadorCartorios.new.importar!

      assert_equal %w[1 2], resultado.criados.sort
      assert_equal true, Cartorio.find_by!(codigo_legado: "1").ativo
      assert_equal false, Cartorio.find_by!(codigo_legado: "2").ativo
    end

    test "é idempotente" do
      inserir(id: "1", nome: "Cartório Um", ativo: true)
      ImportadorCartorios.new.importar!

      resultado = ImportadorCartorios.new.importar!

      assert_empty resultado.criados
      assert_equal 1, resultado.ignorados
    end

    test "pula linhas sem código ou nome" do
      inserir(id: "", nome: "Sem código", ativo: true)
      inserir(id: "3", nome: "", ativo: true)

      resultado = ImportadorCartorios.new.importar!

      assert_empty resultado.criados
      assert_equal 0, Cartorio.count
    end

    private

    def inserir(id:, nome:, ativo:)
      ActiveRecord::Base.connection.execute(<<~SQL)
        INSERT INTO public.cad_protesto (pro_id, pro_cartorio, ativa_sc_titulos)
        VALUES ('#{id}', '#{nome}', #{ativo})
      SQL
    end
  end
end
