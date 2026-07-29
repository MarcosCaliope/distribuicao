require "test_helper"

module Etl
  class ImportadorApresentantesTest < ActiveSupport::TestCase
    setup do
      ActiveRecord::Base.connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS public.cad_apresenta (
          codigo varchar(6), nome varchar(30), endereco varchar(30), fone varchar(20),
          contato varchar(40), agencia varchar(20), tipo char(1), convenio varchar(1),
          scustaantecipada char(1)
        )
      SQL
      ActiveRecord::Base.connection.execute("DELETE FROM public.cad_apresenta")
    end

    teardown do
      ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS public.cad_apresenta")
    end

    test "importa apresentante com convênio válido e custa antecipada" do
      inserir(codigo: "001", nome: "Apresentante Um", convenio: "C", custa: "S")

      ImportadorApresentantes.new.importar!

      apresentante = Apresentante.find_by!(codigo_legado: "001")
      assert_equal "C", apresentante.convenio
      assert apresentante.custa_antecipada
    end

    test "convênio fora de C/I/B vira nil em vez de falhar" do
      inserir(codigo: "002", nome: "Apresentante Dois", convenio: "|", custa: "N")

      resultado = ImportadorApresentantes.new.importar!

      assert_equal [ "002" ], resultado.criados
      assert_nil Apresentante.find_by!(codigo_legado: "002").convenio
    end

    test "é idempotente" do
      inserir(codigo: "001", nome: "Apresentante Um", convenio: "C", custa: "S")
      ImportadorApresentantes.new.importar!

      resultado = ImportadorApresentantes.new.importar!

      assert_empty resultado.criados
      assert_equal 1, resultado.ignorados
    end

    private

    def inserir(codigo:, nome:, convenio:, custa:)
      ActiveRecord::Base.connection.execute(<<~SQL)
        INSERT INTO public.cad_apresenta (codigo, nome, convenio, scustaantecipada)
        VALUES ('#{codigo}', '#{nome}', '#{convenio}', '#{custa}')
      SQL
    end
  end
end
