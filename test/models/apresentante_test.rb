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
end
