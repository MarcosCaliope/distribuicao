require "test_helper"

module Cadastros
  class CartoriosControllerTest < ActionDispatch::IntegrationTest
    setup do
      @cartorio = Cartorio.create!(nome: "1º Ofício", codigo_legado: "1")
    end

    test "exige autenticação" do
      get cadastros_cartorios_path
      assert_redirected_to new_sessao_path
    end

    test "operador sem gerenciar_cadastros não pode acessar" do
      usuario = Usuario.create!(login: "operador_cartorios", nome: "Operador", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "operador") ]
      sign_in_as usuario

      assert_raises(Pundit::NotAuthorizedError) { get cadastros_cartorios_path }
    end

    test "administrador lista cartórios ativos e inativos" do
      sign_in_as_administrador
      Cartorio.create!(nome: "Inativo").inativar!

      get cadastros_cartorios_path
      assert_response :success
    end

    test "cria cartório" do
      sign_in_as_administrador

      assert_difference("Cartorio.count", 1) do
        post cadastros_cartorios_path, params: { cartorio: { nome: "2º Ofício", codigo_legado: "2" } }
      end
      assert_redirected_to cadastros_cartorios_path
    end

    test "não cria cartório inválido e reexibe o form com erro" do
      sign_in_as_administrador

      assert_no_difference("Cartorio.count") do
        post cadastros_cartorios_path, params: { cartorio: { nome: "" } }
      end
      assert_response :unprocessable_entity
    end

    test "atualiza cartório" do
      sign_in_as_administrador

      patch cadastros_cartorio_path(@cartorio), params: { cartorio: { nome: "Novo nome" } }
      assert_redirected_to cadastros_cartorios_path
      assert_equal "Novo nome", @cartorio.reload.nome
    end

    test "destroy inativa em vez de apagar a linha" do
      sign_in_as_administrador

      assert_no_difference("Cartorio.count") do
        delete cadastros_cartorio_path(@cartorio)
      end
      assert_not @cartorio.reload.ativo
    end

    private

    def sign_in_as_administrador
      usuario = Usuario.create!(login: "admin_cartorios", nome: "Admin", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "administrador") ]
      sign_in_as usuario
    end
  end
end
