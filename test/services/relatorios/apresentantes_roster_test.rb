require "test_helper"

module Relatorios
  class ApresentantesRosterTest < ActiveSupport::TestCase
    setup do
      @cda = Apresentante.create!(nome: "Zebra CDA", codigo_legado: "003", convenio: "C")
      @isento = Apresentante.create!(nome: "Alfa Isento", codigo_legado: "001", convenio: "I")
      @banco = Apresentante.create!(nome: "Meio Banco", codigo_legado: "002", convenio: "B")
    end

    test "alfabetica ordena por nome, todos os convênios" do
      dataset = ApresentantesRoster.new(modo: "alfabetica").gerar

      nomes = dataset.linhas.map(&:second)
      assert_equal [ "Alfa Isento", "Meio Banco", "Zebra CDA" ], nomes
    end

    test "numerica ordena por código" do
      dataset = ApresentantesRoster.new(modo: "numerica").gerar

      codigos = dataset.linhas.map(&:first)
      assert_equal %w[001 002 003], codigos
    end

    test "cda filtra só convenio C" do
      dataset = ApresentantesRoster.new(modo: "cda").gerar

      assert_equal [ "Zebra CDA" ], dataset.linhas.map(&:second)
    end

    test "modo desconhecido cai para alfabetica" do
      dataset = ApresentantesRoster.new(modo: "chute").gerar

      assert_equal 3, dataset.linhas.size
    end
  end
end
