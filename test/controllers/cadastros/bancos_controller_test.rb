require "test_helper"

module Cadastros
  class BancosControllerTest < ActionDispatch::IntegrationTest
    setup do
      @banco = Banco.create!(codigo_legado: "001", nome: "Banco do Brasil")
    end

    test "exige autenticação" do
      get cadastros_bancos_path
      assert_redirected_to new_sessao_path
    end

    test "operador sem gerenciar_cadastros não pode acessar" do
      usuario = Usuario.create!(login: "operador_bancos", nome: "Operador", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "operador") ]
      sign_in_as usuario

      assert_raises(Pundit::NotAuthorizedError) { get cadastros_bancos_path }
    end

    test "administrador lista bancos ativos e inativos" do
      sign_in_as_administrador
      Banco.create!(codigo_legado: "999", nome: "Inativo").inativar!

      get cadastros_bancos_path
      assert_response :success
    end

    test "cria banco associado a um apresentante" do
      sign_in_as_administrador
      apresentante = Apresentante.create!(nome: "Apresentante", codigo_legado: "001")

      assert_difference("Banco.count", 1) do
        post cadastros_bancos_path, params: { banco: { codigo_legado: "002", nome: "Novo banco", apresentante_id: apresentante.id } }
      end
      assert_redirected_to cadastros_bancos_path
      assert_equal apresentante, Banco.order(:created_at).last.apresentante
    end

    test "não cria banco inválido e reexibe o form com erro" do
      sign_in_as_administrador

      assert_no_difference("Banco.count") do
        post cadastros_bancos_path, params: { banco: { nome: "" } }
      end
      assert_response :unprocessable_entity
    end

    test "atualiza banco" do
      sign_in_as_administrador

      patch cadastros_banco_path(@banco), params: { banco: { nome: "Novo nome" } }
      assert_redirected_to cadastros_bancos_path
      assert_equal "Novo nome", @banco.reload.nome
    end

    test "destroy inativa em vez de apagar a linha" do
      sign_in_as_administrador

      assert_no_difference("Banco.count") do
        delete cadastros_banco_path(@banco)
      end
      assert_not @banco.reload.ativo
    end

    private

    def sign_in_as_administrador
      usuario = Usuario.create!(login: "admin_bancos", nome: "Admin", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "administrador") ]
      sign_in_as usuario
    end
  end
end
