require "test_helper"

module Relatorios
  class ArrecadacaoControllerTest < ActionDispatch::IntegrationTest
    setup do
      usuario = Usuario.create!(login: "operador_teste", nome: "Operador", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "operador") ]
      sign_in_as usuario
    end

    test "resumo exige autenticação e responde em html e pdf" do
      delete sessao_url
      get relatorios_arrecadacao_resumo_path
      assert_redirected_to new_sessao_path

      sign_in_as Usuario.find_by!(login: "operador_teste")
      get relatorios_arrecadacao_resumo_path
      assert_response :success

      get relatorios_arrecadacao_resumo_path(format: :pdf)
      assert_response :success
      assert_equal "application/pdf", @response.media_type
    end

    test "total_titulos exige autenticação e responde em html e pdf" do
      delete sessao_url
      get relatorios_arrecadacao_total_titulos_path
      assert_redirected_to new_sessao_path

      sign_in_as Usuario.find_by!(login: "operador_teste")
      get relatorios_arrecadacao_total_titulos_path
      assert_response :success

      get relatorios_arrecadacao_total_titulos_path(format: :pdf)
      assert_response :success
    end
  end
end
