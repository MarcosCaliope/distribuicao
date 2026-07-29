require "test_helper"

module Cadastros
  class FaixaCustasControllerTest < ActionDispatch::IntegrationTest
    setup do
      @faixa_custa = FaixaCusta.create!(sequencial: 1, tipo: "A", limite_inferior: 0, limite_superior: 100)
    end

    test "exige autenticação" do
      get cadastros_faixa_custas_path
      assert_redirected_to new_sessao_path
    end

    test "operador sem gerenciar_cadastros não pode acessar" do
      usuario = Usuario.create!(login: "operador_faixas", nome: "Operador", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "operador") ]
      sign_in_as usuario

      assert_raises(Pundit::NotAuthorizedError) { get cadastros_faixa_custas_path }
    end

    test "administrador lista faixas de custa ativas e inativas" do
      sign_in_as_administrador
      FaixaCusta.create!(sequencial: 2, tipo: "B", limite_inferior: 100, limite_superior: 200).inativar!

      get cadastros_faixa_custas_path
      assert_response :success
    end

    test "cria faixa de custa" do
      sign_in_as_administrador

      assert_difference("FaixaCusta.count", 1) do
        post cadastros_faixa_custas_path, params: { faixa_custa: { sequencial: 3, tipo: "C", limite_inferior: 200, limite_superior: 300 } }
      end
      assert_redirected_to cadastros_faixa_custas_path
    end

    test "não cria faixa de custa inválida e reexibe o form com erro" do
      sign_in_as_administrador

      assert_no_difference("FaixaCusta.count") do
        post cadastros_faixa_custas_path, params: { faixa_custa: { tipo: "" } }
      end
      assert_response :unprocessable_entity
    end

    test "atualiza faixa de custa" do
      sign_in_as_administrador

      patch cadastros_faixa_custa_path(@faixa_custa), params: { faixa_custa: { tipo: "Z" } }
      assert_redirected_to cadastros_faixa_custas_path
      assert_equal "Z", @faixa_custa.reload.tipo
    end

    test "destroy inativa em vez de apagar a linha" do
      sign_in_as_administrador

      assert_no_difference("FaixaCusta.count") do
        delete cadastros_faixa_custa_path(@faixa_custa)
      end
      assert_not @faixa_custa.reload.ativo
    end

    private

    def sign_in_as_administrador
      usuario = Usuario.create!(login: "admin_faixas", nome: "Admin", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "administrador") ]
      sign_in_as usuario
    end
  end
end
