require "test_helper"

class BancoTest < ActiveSupport::TestCase
  test "scope ativos retorna só bancos ativos" do
    ativo = Banco.create!(codigo_legado: "001", nome: "Ativo")
    inativo = Banco.create!(codigo_legado: "002", nome: "Inativo").tap(&:inativar!)

    assert_includes Banco.ativos, ativo
    assert_not_includes Banco.ativos, inativo
  end

  test "inativar! desativa sem apagar a linha" do
    banco = Banco.create!(codigo_legado: "001", nome: "Banco")

    assert_difference("Banco.count", 0) { banco.inativar! }
    assert_not banco.ativo
  end

  test "codigo_alfa vazio normaliza pra nil" do
    banco = Banco.create!(codigo_legado: "001", nome: "Banco", codigo_alfa: "")

    assert_nil banco.codigo_alfa
  end

  test "não permite dois bancos com o mesmo codigo_alfa" do
    Banco.create!(codigo_legado: "001", nome: "Primeiro", codigo_alfa: "BB")
    duplicado = Banco.new(codigo_legado: "002", nome: "Segundo", codigo_alfa: "BB")

    assert_not duplicado.valid?
  end
end
