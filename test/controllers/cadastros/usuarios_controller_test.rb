require "test_helper"

module Cadastros
  class UsuariosControllerTest < ActionDispatch::IntegrationTest
    setup do
      @usuario = Usuario.create!(login: "usuario_teste", nome: "Usuário Teste", password: SENHA_PADRAO_TESTE)
      @usuario.perfis = [ Perfil.find_by!(nome: "operador") ]
    end

    test "exige autenticação" do
      get cadastros_usuarios_path
      assert_redirected_to new_sessao_path
    end

    test "operador sem gerenciar_cadastros não pode acessar" do
      sign_in_as @usuario

      assert_raises(Pundit::NotAuthorizedError) { get cadastros_usuarios_path }
    end

    test "administrador lista usuários ativos e inativos" do
      sign_in_as_administrador
      Usuario.create!(login: "inativo", nome: "Inativo", password: SENHA_PADRAO_TESTE).inativar!

      get cadastros_usuarios_path
      assert_response :success
    end

    test "cria usuário com senha temporária gerada e perfis atribuídos" do
      sign_in_as_administrador
      perfil_operador = Perfil.find_by!(nome: "operador")

      assert_difference("Usuario.count", 1) do
        post cadastros_usuarios_path, params: { usuario: { login: "novo", nome: "Novo", perfil_ids: [ perfil_operador.id ] } }
      end
      assert_redirected_to cadastros_usuarios_path

      criado = Usuario.find_by!(login: "novo")
      assert criado.deve_trocar_senha
      assert_equal [ perfil_operador ], criado.perfis
    end

    test "não cria usuário inválido e reexibe o form com erro" do
      sign_in_as_administrador

      assert_no_difference("Usuario.count") do
        post cadastros_usuarios_path, params: { usuario: { login: "", nome: "" } }
      end
      assert_response :unprocessable_entity
    end

    test "atualiza usuário e seus perfis" do
      sign_in_as_administrador
      perfil_administrador = Perfil.find_by!(nome: "administrador")

      patch cadastros_usuario_path(@usuario), params: { usuario: { nome: "Novo nome", perfil_ids: [ perfil_administrador.id ] } }
      assert_redirected_to cadastros_usuarios_path
      @usuario.reload
      assert_equal "Novo nome", @usuario.nome
      assert_equal [ perfil_administrador ], @usuario.perfis
    end

    test "destroy inativa em vez de apagar a linha" do
      sign_in_as_administrador

      assert_no_difference("Usuario.count") do
        delete cadastros_usuario_path(@usuario)
      end
      assert_not @usuario.reload.ativo
    end

    test "excluir apaga a linha de verdade" do
      sign_in_as_administrador

      assert_difference("Usuario.count", -1) do
        delete excluir_cadastros_usuario_path(@usuario)
      end
      assert_redirected_to cadastros_usuarios_path
      assert_not Usuario.exists?(@usuario.id)
    end

    test "resetar_senha gera nova senha e força troca no próximo login" do
      sign_in_as_administrador
      @usuario.update!(deve_trocar_senha: false)

      post resetar_senha_cadastros_usuario_path(@usuario)
      assert_redirected_to cadastros_usuarios_path
      assert @usuario.reload.deve_trocar_senha
      assert_not @usuario.authenticate(SENHA_PADRAO_TESTE)
    end

    private

    def sign_in_as_administrador
      usuario = Usuario.create!(login: "admin_usuarios", nome: "Admin", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "administrador") ]
      sign_in_as usuario
    end
  end
end
