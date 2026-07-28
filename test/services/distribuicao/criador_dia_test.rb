require "test_helper"

module Distribuicao
  class CriadorDiaTest < ActiveSupport::TestCase
    setup do
      @cartorio = Cartorio.create!(nome: "1º Ofício", codigo_legado: "1")
      @faixa = FaixaCusta.create!(sequencial: 1, tipo: "A", limite_inferior: 0.01, limite_superior: 100.00)
    end

    test "cria uma vaga por cartório ativo x faixa" do
      Cartorio.create!(nome: "2º Ofício", codigo_legado: "2")
      inativo = Cartorio.create!(nome: "Inativo", codigo_legado: "3", ativo: false)
      FaixaCusta.create!(sequencial: 2, tipo: "B", limite_inferior: 100.01, limite_superior: 200.00)

      CriadorDia.new(Date.current).criar!

      assert_equal 4, VagaDistribuicao.where(data: Date.current).count
      assert_not VagaDistribuicao.exists?(data: Date.current, cartorio: inativo)
    end

    test "é idempotente para a mesma data" do
      CriadorDia.new(Date.current).criar!

      assert_no_difference "VagaDistribuicao.count" do
        CriadorDia.new(Date.current).criar!
      end
    end

    test "herda livre do registro mais recente anterior para o mesmo par cartório/faixa" do
      VagaDistribuicao.create!(data: 2.days.ago.to_date, cartorio: @cartorio, faixa_custa: @faixa, livre: true)
      VagaDistribuicao.create!(data: 1.day.ago.to_date, cartorio: @cartorio, faixa_custa: @faixa, livre: false)

      CriadorDia.new(Date.current).criar!

      vaga = VagaDistribuicao.find_by(data: Date.current, cartorio: @cartorio, faixa_custa: @faixa)
      assert_equal false, vaga.livre
    end

    test "usa false quando não há registro anterior" do
      CriadorDia.new(Date.current).criar!

      vaga = VagaDistribuicao.find_by(data: Date.current, cartorio: @cartorio, faixa_custa: @faixa)
      assert_equal false, vaga.livre
    end
  end
end
