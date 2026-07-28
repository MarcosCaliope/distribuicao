require "test_helper"

module Relatorios
  class TitulosControllerTest < ActionDispatch::IntegrationTest
    setup do
      @credenciais = ActionController::HttpAuthentication::Basic.encode_credentials(
        ENV["RELATORIOS_USUARIO"], ENV["RELATORIOS_SENHA"]
      )
    end

    test "exige autenticação básica" do
      get relatorios_titulos_eventuais_path
      assert_response :unauthorized
    end

    test "eventuais responde em html e pdf com credenciais corretas" do
      get relatorios_titulos_eventuais_path, headers: { "Authorization" => @credenciais }
      assert_response :success

      get relatorios_titulos_eventuais_path(format: :pdf), headers: { "Authorization" => @credenciais }
      assert_response :success
      assert_equal "application/pdf", @response.media_type
    end

    test "por_apresentante sem apresentante_id mostra só o formulário" do
      get relatorios_titulos_por_apresentante_path, headers: { "Authorization" => @credenciais }
      assert_response :success
    end

    test "por_devedor sem cpf_cnpj mostra só o formulário" do
      get relatorios_titulos_por_devedor_path, headers: { "Authorization" => @credenciais }
      assert_response :success
    end
  end
end
