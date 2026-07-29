require "test_helper"

class CartorioTest < ActiveSupport::TestCase
  test "scope ativos retorna só cartórios ativos" do
    ativo = Cartorio.create!(nome: "Ativo")
    inativo = Cartorio.create!(nome: "Inativo").tap(&:inativar!)

    assert_includes Cartorio.ativos, ativo
    assert_not_includes Cartorio.ativos, inativo
  end

  test "inativar! desativa sem apagar a linha" do
    cartorio = Cartorio.create!(nome: "Cartório")

    assert_difference("Cartorio.count", 0) { cartorio.inativar! }
    assert_not cartorio.ativo
  end

  test "codigo_legado vazio normaliza pra nil" do
    cartorio = Cartorio.create!(nome: "Cartório", codigo_legado: "")

    assert_nil cartorio.codigo_legado
  end

  test "não permite dois cartórios com o mesmo codigo_legado" do
    Cartorio.create!(nome: "Primeiro", codigo_legado: "1")
    duplicado = Cartorio.new(nome: "Segundo", codigo_legado: "1")

    assert_not duplicado.valid?
  end
end
