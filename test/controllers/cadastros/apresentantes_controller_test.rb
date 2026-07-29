require "test_helper"

module Cadastros
  class ApresentantesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @apresentante = Apresentante.create!(nome: "Banco do Brasil", codigo_legado: "001", convenio: "B")
    end

    test "exige autenticação" do
      get cadastros_apresentantes_path
      assert_redirected_to new_sessao_path
    end

    test "operador sem gerenciar_cadastros não pode acessar" do
      usuario = Usuario.create!(login: "operador_apresentantes", nome: "Operador", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "operador") ]
      sign_in_as usuario

      assert_raises(Pundit::NotAuthorizedError) { get cadastros_apresentantes_path }
    end

    test "administrador lista apresentantes ativos e inativos" do
      sign_in_as_administrador
      Apresentante.create!(nome: "Inativo").inativar!

      get cadastros_apresentantes_path
      assert_response :success
    end

    test "cria apresentante" do
      sign_in_as_administrador

      assert_difference("Apresentante.count", 1) do
        post cadastros_apresentantes_path, params: { apresentante: { nome: "Novo apresentante", codigo_legado: "002", convenio: "C" } }
      end
      assert_redirected_to cadastros_apresentantes_path
    end

    test "não cria apresentante inválido e reexibe o form com erro" do
      sign_in_as_administrador

      assert_no_difference("Apresentante.count") do
        post cadastros_apresentantes_path, params: { apresentante: { nome: "" } }
      end
      assert_response :unprocessable_entity
    end

    test "atualiza apresentante" do
      sign_in_as_administrador

      patch cadastros_apresentante_path(@apresentante), params: { apresentante: { nome: "Novo nome" } }
      assert_redirected_to cadastros_apresentantes_path
      assert_equal "Novo nome", @apresentante.reload.nome
    end

    test "destroy inativa em vez de apagar a linha" do
      sign_in_as_administrador

      assert_no_difference("Apresentante.count") do
        delete cadastros_apresentante_path(@apresentante)
      end
      assert_not @apresentante.reload.ativo
    end

    private

    def sign_in_as_administrador
      usuario = Usuario.create!(login: "admin_apresentantes", nome: "Admin", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "administrador") ]
      sign_in_as usuario
    end
  end
end
