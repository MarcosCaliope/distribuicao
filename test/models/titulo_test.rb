require "test_helper"

class TituloTest < ActiveSupport::TestCase
  setup do
    @devedor = Devedor.create!(tipo_documento: "CNPJ", cpf_cnpj: "07240450000109", nome: "DEVEDOR PRINCIPAL")
  end

  def criar_titulo(numero_titulo:, nome_devedor: "DEVEDOR PRINCIPAL", cpf_cnpj_devedor: "07240450000109")
    Titulo.create!(
      devedor: @devedor,
      tipo_documento_devedor: "CNPJ",
      cpf_cnpj_devedor: cpf_cnpj_devedor,
      nome_devedor: nome_devedor,
      numero_titulo: numero_titulo,
      data_recebimento: Date.current,
      valor: 100
    )
  end

  test "pesquisar filtra por numero_titulo, nome_devedor ou cpf_cnpj_devedor" do
    alvo = criar_titulo(numero_titulo: "12345")
    outro = criar_titulo(numero_titulo: "99999", nome_devedor: "OUTRO DEVEDOR", cpf_cnpj_devedor: "11111111000191")

    assert_includes Titulo.pesquisar("12345"), alvo
    assert_not_includes Titulo.pesquisar("12345"), outro
    assert_includes Titulo.pesquisar("DEVEDOR PRINCIPAL"), alvo
    assert_includes Titulo.pesquisar("07240450000109"), alvo
  end
end
