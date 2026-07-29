require "test_helper"

class SenhasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @usuario = Usuario.create!(
      login: "senhas_teste", nome: "Teste", password: SENHA_PADRAO_TESTE, deve_trocar_senha: true
    )
    @usuario.perfis = [ Perfil.find_by!(nome: "operador") ]
    sign_in_as @usuario
  end

  test "usuário com deve_trocar_senha é redirecionado pra troca de senha em qualquer tela" do
    get relatorios_titulos_eventuais_path

    assert_redirected_to edit_senha_path
  end

  test "a própria tela de troca de senha é acessível mesmo com deve_trocar_senha" do
    get edit_senha_path

    assert_response :success
  end

  test "troca de senha com senha atual correta funciona e limpa deve_trocar_senha" do
    patch senha_path, params: {
      senha_atual: SENHA_PADRAO_TESTE, nova_senha: "nova-senha-456", nova_senha_confirmacao: "nova-senha-456"
    }

    assert_redirected_to relatorios_menu_path
    assert_not @usuario.reload.deve_trocar_senha
    assert @usuario.authenticate("nova-senha-456")
  end

  test "troca de senha com senha atual errada é rejeitada" do
    patch senha_path, params: {
      senha_atual: "senha-errada", nova_senha: "nova-senha-456", nova_senha_confirmacao: "nova-senha-456"
    }

    assert_redirected_to edit_senha_path
    assert @usuario.reload.deve_trocar_senha
  end

  test "confirmação que não confere é rejeitada" do
    patch senha_path, params: {
      senha_atual: SENHA_PADRAO_TESTE, nova_senha: "nova-senha-456", nova_senha_confirmacao: "outra-coisa"
    }

    assert_redirected_to edit_senha_path
    assert @usuario.reload.deve_trocar_senha
  end
end
