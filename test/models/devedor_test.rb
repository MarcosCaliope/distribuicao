require "test_helper"

class DevedorTest < ActiveSupport::TestCase
  test "scope ativos retorna só devedores ativos" do
    ativo = Devedor.create!(tipo_documento: "CPF", cpf_cnpj: "11111111111", nome: "Ativo")
    inativo = Devedor.create!(tipo_documento: "CPF", cpf_cnpj: "22222222222", nome: "Inativo").tap(&:inativar!)

    assert_includes Devedor.ativos, ativo
    assert_not_includes Devedor.ativos, inativo
  end

  test "inativar! desativa sem apagar a linha" do
    devedor = Devedor.create!(tipo_documento: "CPF", cpf_cnpj: "11111111111", nome: "Devedor")

    assert_difference("Devedor.count", 0) { devedor.inativar! }
    assert_not devedor.ativo
  end

  test "não permite dois devedores com o mesmo tipo_documento e cpf_cnpj" do
    Devedor.create!(tipo_documento: "CPF", cpf_cnpj: "11111111111", nome: "Primeiro")
    duplicado = Devedor.new(tipo_documento: "CPF", cpf_cnpj: "11111111111", nome: "Segundo")

    assert_not duplicado.valid?
  end

  test "mesmo cpf_cnpj é permitido com tipo_documento diferente" do
    Devedor.create!(tipo_documento: "CPF", cpf_cnpj: "11111111111", nome: "Primeiro")
    outro = Devedor.new(tipo_documento: "CNPJ", cpf_cnpj: "11111111111", nome: "Segundo")

    assert outro.valid?
  end

  test "pesquisar filtra por nome ou cpf_cnpj" do
    alvo = Devedor.create!(tipo_documento: "CPF", cpf_cnpj: "11111111111", nome: "Banco do Brasil")
    outro = Devedor.create!(tipo_documento: "CPF", cpf_cnpj: "22222222222", nome: "Outro")

    assert_includes Devedor.pesquisar("brasil"), alvo
    assert_not_includes Devedor.pesquisar("brasil"), outro
    assert_includes Devedor.pesquisar("11111111111"), alvo
  end
end
