require "test_helper"

class SessoesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @usuario = Usuario.create!(login: "sessoes_teste", nome: "Teste", password: SENHA_PADRAO_TESTE)
  end

  test "login com credenciais corretas cria sessão e redireciona" do
    post sessao_url, params: { login: @usuario.login, password: SENHA_PADRAO_TESTE }

    assert_redirected_to relatorios_titulos_eventuais_path
    assert_equal 1, @usuario.sessoes.count
  end

  test "login com senha errada não autentica" do
    post sessao_url, params: { login: @usuario.login, password: "senha-errada" }

    assert_redirected_to new_sessao_path
    assert_equal 0, @usuario.sessoes.count
  end

  test "login de usuário inativo não autentica" do
    @usuario.update!(ativo: false)

    post sessao_url, params: { login: @usuario.login, password: SENHA_PADRAO_TESTE }

    assert_redirected_to new_sessao_path
  end

  test "logout encerra a sessão" do
    sign_in_as @usuario
    assert_equal 1, @usuario.sessoes.count

    delete sessao_url

    assert_redirected_to new_sessao_path
    assert_equal 0, @usuario.sessoes.count
  end
end
