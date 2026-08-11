require "test_helper"

class ApresentanteTest < ActiveSupport::TestCase
  test "scope ativos retorna só apresentantes ativos" do
    ativo = Apresentante.create!(nome: "Ativo")
    inativo = Apresentante.create!(nome: "Inativo").tap(&:inativar!)

    assert_includes Apresentante.ativos, ativo
    assert_not_includes Apresentante.ativos, inativo
  end

  test "inativar! desativa sem apagar a linha" do
    apresentante = Apresentante.create!(nome: "Apresentante")

    assert_difference("Apresentante.count", 0) { apresentante.inativar! }
    assert_not apresentante.ativo
  end

  test "codigo_legado vazio normaliza pra nil" do
    apresentante = Apresentante.create!(nome: "Apresentante", codigo_legado: "")

    assert_nil apresentante.codigo_legado
  end

  test "não permite dois apresentantes com o mesmo codigo_legado" do
    Apresentante.create!(nome: "Primeiro", codigo_legado: "1")
    duplicado = Apresentante.new(nome: "Segundo", codigo_legado: "1")

    assert_not duplicado.valid?
  end

  test "pesquisar filtra por nome ou codigo_legado, sem diferenciar maiúsculas" do
    banco_brasil = Apresentante.create!(nome: "Banco do Brasil", codigo_legado: "001")
    outro = Apresentante.create!(nome: "Outro", codigo_legado: "002")

    assert_includes Apresentante.pesquisar("brasil"), banco_brasil
    assert_not_includes Apresentante.pesquisar("brasil"), outro
    assert_includes Apresentante.pesquisar("001"), banco_brasil
  end

  test "pesquisar com termo em branco retorna todos" do
    Apresentante.create!(nome: "Apresentante")

    assert_equal Apresentante.count, Apresentante.pesquisar(nil).count
    assert_equal Apresentante.count, Apresentante.pesquisar("").count
  end
end
