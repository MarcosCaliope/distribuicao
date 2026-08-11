require "test_helper"

module Etl
  class ImportadorBancosTest < ActiveSupport::TestCase
    setup do
      ActiveRecord::Base.connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS public.cad_bancos (
          banco varchar(30), codigo varchar(6), codalfa varchar(6), vcusta varchar(10),
          bngera boolean, iseqconf integer, email varchar(50), cd2 varchar(6)
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

    test "linka apresentante_id via cd2 na criação" do
      apresentante = Apresentante.create!(nome: "Trademaster", codigo_legado: "1594")
      inserir(codigo: "667", nome: "Trademaster Banco", codalfa: "", vcusta: "0000000000", bngera: false, cd2: "1594")

      ImportadorBancos.new.importar!

      assert_equal apresentante, Banco.find_by!(codigo_legado: "667").apresentante
    end

    test "cd2 sem Apresentante correspondente fica sem link, sem falhar a importação" do
      inserir(codigo: "667", nome: "Trademaster Banco", codalfa: "", vcusta: "0000000000", bngera: false, cd2: "9999")

      resultado = ImportadorBancos.new.importar!

      assert_equal %w[667], resultado.criados
      assert_nil Banco.find_by!(codigo_legado: "667").apresentante_id
    end

    test "backfilla apresentante_id de bancos já importados sem sobrescrever um já linkado" do
      apresentante = Apresentante.create!(nome: "Trademaster", codigo_legado: "1594")
      outro_apresentante = Apresentante.create!(nome: "Outro", codigo_legado: "2000")
      Banco.create!(codigo_legado: "667", nome: "Trademaster Banco")
      Banco.create!(codigo_legado: "668", nome: "Já linkado", apresentante_id: outro_apresentante.id)
      inserir(codigo: "667", nome: "Trademaster Banco", codalfa: "", vcusta: "0000000000", bngera: false, cd2: "1594")
      inserir(codigo: "668", nome: "Já linkado", codalfa: "", vcusta: "0000000000", bngera: false, cd2: "1594")

      resultado = ImportadorBancos.new.importar!

      assert_empty resultado.criados
      assert_equal 2, resultado.ignorados
      assert_equal apresentante, Banco.find_by!(codigo_legado: "667").apresentante
      assert_equal outro_apresentante, Banco.find_by!(codigo_legado: "668").apresentante
    end

    private

    def inserir(codigo:, nome:, codalfa:, vcusta:, bngera:, cd2: nil)
      ActiveRecord::Base.connection.execute(<<~SQL)
        INSERT INTO public.cad_bancos (codigo, banco, codalfa, vcusta, bngera, cd2)
        VALUES ('#{codigo}', '#{nome}', '#{codalfa}', '#{vcusta}', #{bngera}, #{cd2.nil? ? "NULL" : "'#{cd2}'"})
      SQL
    end
  end
end
