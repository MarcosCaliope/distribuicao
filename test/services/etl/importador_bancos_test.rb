require "test_helper"

module Etl
  class ImportadorBancosTest < ActiveSupport::TestCase
    setup do
      ActiveRecord::Base.connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS public.cad_bancos (
          banco varchar(30), codigo varchar(6), codalfa varchar(6), vcusta varchar(10),
          bngera boolean, iseqconf integer, email varchar(50)
        )
      SQL
      ActiveRecord::Base.connection.execute("DELETE FROM public.cad_bancos")
    end

    teardown do
      ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS public.cad_bancos")
    end

    test "importa banco convertendo vcusta de centavos e codalfa em branco para nil" do
      inserir(codigo: "001", nome: "Banco Um", codalfa: "ABC", vcusta: "0000001540", bngera: true)
      inserir(codigo: "002", nome: "Banco Dois", codalfa: "      ", vcusta: "0000000000", bngera: false)

      resultado = ImportadorBancos.new.importar!

      assert_equal %w[001 002], resultado.criados.sort
      banco1 = Banco.find_by!(codigo_legado: "001")
      assert_equal "ABC", banco1.codigo_alfa
      assert_equal 15.40, banco1.valor_custa
      assert banco1.gera_remessa_cartorio

      banco2 = Banco.find_by!(codigo_legado: "002")
      assert_nil banco2.codigo_alfa
      assert_not banco2.gera_remessa_cartorio
    end

    test "é idempotente" do
      inserir(codigo: "001", nome: "Banco Um", codalfa: "ABC", vcusta: "0000001540", bngera: true)
      ImportadorBancos.new.importar!

      resultado = ImportadorBancos.new.importar!

      assert_empty resultado.criados
      assert_equal 1, resultado.ignorados
    end

    private

    def inserir(codigo:, nome:, codalfa:, vcusta:, bngera:)
      ActiveRecord::Base.connection.execute(<<~SQL)
        INSERT INTO public.cad_bancos (codigo, banco, codalfa, vcusta, bngera)
        VALUES ('#{codigo}', '#{nome}', '#{codalfa}', '#{vcusta}', #{bngera})
      SQL
    end
  end
end
