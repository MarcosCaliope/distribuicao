require "test_helper"

module Relatorios
  class ArrecadacaoControllerTest < ActionDispatch::IntegrationTest
    setup do
      @credenciais = ActionController::HttpAuthentication::Basic.encode_credentials(
        ENV["RELATORIOS_USUARIO"], ENV["RELATORIOS_SENHA"]
      )
    end

    test "resumo exige autenticação e responde em html e pdf" do
      get relatorios_arrecadacao_resumo_path
      assert_response :unauthorized

      get relatorios_arrecadacao_resumo_path, headers: { "Authorization" => @credenciais }
      assert_response :success

      get relatorios_arrecadacao_resumo_path(format: :pdf), headers: { "Authorization" => @credenciais }
      assert_response :success
      assert_equal "application/pdf", @response.media_type
    end

    test "total_titulos exige autenticação e responde em html e pdf" do
      get relatorios_arrecadacao_total_titulos_path
      assert_response :unauthorized

      get relatorios_arrecadacao_total_titulos_path, headers: { "Authorization" => @credenciais }
      assert_response :success

      get relatorios_arrecadacao_total_titulos_path(format: :pdf), headers: { "Authorization" => @credenciais }
      assert_response :success
    end
  end
end
