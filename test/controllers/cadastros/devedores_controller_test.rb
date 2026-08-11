require "test_helper"

module Cadastros
  class DevedoresControllerTest < ActionDispatch::IntegrationTest
    setup do
      @devedor = Devedor.create!(tipo_documento: "CNPJ", cpf_cnpj: "07240450000109", nome: "Devedor Principal")
    end

    test "exige autenticação" do
      get cadastros_devedores_path
      assert_redirected_to new_sessao_path
    end

    test "operador sem gerenciar_cadastros não pode acessar" do
      usuario = Usuario.create!(login: "operador_devedores", nome: "Operador", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "operador") ]
      sign_in_as usuario

      assert_raises(Pundit::NotAuthorizedError) { get cadastros_devedores_path }
    end

    test "administrador lista devedores ativos e inativos" do
      sign_in_as_administrador
      Devedor.create!(tipo_documento: "CPF", cpf_cnpj: "11111111111", nome: "Inativo").inativar!

      get cadastros_devedores_path
      assert_response :success
    end

    test "filtra a lista pelo parâmetro q" do
      sign_in_as_administrador
      Devedor.create!(tipo_documento: "CPF", cpf_cnpj: "11111111111", nome: "Não deve aparecer")

      get cadastros_devedores_path, params: { q: "Devedor Principal" }
      assert_response :success
      assert_match "Devedor Principal", response.body
      assert_no_match "Não deve aparecer", response.body
    end

    test "cria devedor" do
      sign_in_as_administrador

      assert_difference("Devedor.count", 1) do
        post cadastros_devedores_path, params: {
          devedor: { tipo_documento: "CPF", cpf_cnpj: "22222222222", nome: "Novo devedor", bairro: "Aldeota" }
        }
      end
      assert_redirected_to cadastros_devedores_path
    end

    test "não cria devedor inválido e reexibe o form com erro" do
      sign_in_as_administrador

      assert_no_difference("Devedor.count") do
        post cadastros_devedores_path, params: { devedor: { tipo_documento: "", cpf_cnpj: "" } }
      end
      assert_response :unprocessable_entity
    end

    test "atualiza devedor" do
      sign_in_as_administrador

      patch cadastros_devedor_path(@devedor), params: { devedor: { nome: "Novo nome" } }
      assert_redirected_to cadastros_devedores_path
      assert_equal "Novo nome", @devedor.reload.nome
    end

    test "destroy inativa em vez de apagar a linha" do
      sign_in_as_administrador

      assert_no_difference("Devedor.count") do
        delete cadastros_devedor_path(@devedor)
      end
      assert_not @devedor.reload.ativo
    end

    private

    def sign_in_as_administrador
      usuario = Usuario.create!(login: "admin_devedores", nome: "Admin", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "administrador") ]
      sign_in_as usuario
    end
  end
end
