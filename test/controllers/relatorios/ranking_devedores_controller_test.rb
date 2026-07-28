require "test_helper"

module Relatorios
  class RankingDevedoresControllerTest < ActionDispatch::IntegrationTest
    test "exige autenticação e responde em html e pdf" do
      get relatorios_ranking_devedores_path
      assert_response :unauthorized

      credenciais = ActionController::HttpAuthentication::Basic.encode_credentials(
        ENV["RELATORIOS_USUARIO"], ENV["RELATORIOS_SENHA"]
      )
      get relatorios_ranking_devedores_path, headers: { "Authorization" => credenciais }
      assert_response :success

      get relatorios_ranking_devedores_path(format: :pdf), headers: { "Authorization" => credenciais }
      assert_response :success
    end
  end
end
