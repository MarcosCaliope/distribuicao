require "test_helper"

class UsuarioTest < ActiveSupport::TestCase
  test "tem_permissao? verifica através dos perfis" do
    usuario = Usuario.create!(login: "usuario_teste", nome: "Teste", password: "senha12345")

    assert_not usuario.tem_permissao?("ver_relatorios")

    usuario.perfis << Perfil.find_by!(nome: "operador")

    assert usuario.tem_permissao?("ver_relatorios")
    assert_not usuario.tem_permissao?("permissao_inexistente")
  end

  test "login é normalizado para minúsculas" do
    usuario = Usuario.create!(login: "MAIUSCULO", nome: "Teste", password: "senha12345")

    assert_equal "maiusculo", usuario.login
  end

  test "scope ativos exclui usuários inativos" do
    ativo = Usuario.create!(login: "ativo_teste", nome: "Ativo", password: "senha12345")
    inativo = Usuario.create!(login: "inativo_teste", nome: "Inativo", password: "senha12345", ativo: false)

    assert_includes Usuario.ativos, ativo
    assert_not_includes Usuario.ativos, inativo
  end
end
