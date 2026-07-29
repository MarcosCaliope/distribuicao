require "test_helper"

class TipoTituloTest < ActiveSupport::TestCase
  test "scope ativos retorna só tipos de título ativos" do
    ativo = TipoTitulo.create!(codigo_legado: "01", descricao: "Ativo", abreviatura: "ATI")
    inativo = TipoTitulo.create!(codigo_legado: "02", descricao: "Inativo", abreviatura: "INA").tap(&:inativar!)

    assert_includes TipoTitulo.ativos, ativo
    assert_not_includes TipoTitulo.ativos, inativo
  end

  test "inativar! desativa sem apagar a linha" do
    tipo_titulo = TipoTitulo.create!(codigo_legado: "01", descricao: "Duplicata", abreviatura: "DM")

    assert_difference("TipoTitulo.count", 0) { tipo_titulo.inativar! }
    assert_not tipo_titulo.ativo
  end

  test "exige codigo_legado" do
    tipo_titulo = TipoTitulo.new(descricao: "Duplicata", abreviatura: "DM")

    assert_not tipo_titulo.valid?
  end

  test "codigo_legado vazio normaliza pra nil, o que falha a presence" do
    tipo_titulo = TipoTitulo.new(codigo_legado: "", descricao: "Duplicata", abreviatura: "DM")

    assert_nil tipo_titulo.codigo_legado
    assert_not tipo_titulo.valid?
  end

  test "não permite dois tipos de título com o mesmo codigo_legado" do
    TipoTitulo.create!(codigo_legado: "01", descricao: "Primeiro", abreviatura: "PRI")
    duplicado = TipoTitulo.new(codigo_legado: "01", descricao: "Segundo", abreviatura: "SEG")

    assert_not duplicado.valid?
  end
end
