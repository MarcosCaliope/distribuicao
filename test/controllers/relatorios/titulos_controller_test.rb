require "test_helper"

module Relatorios
  class TitulosControllerTest < ActionDispatch::IntegrationTest
    setup do
      usuario = Usuario.create!(login: "operador_teste", nome: "Operador", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "operador") ]
      sign_in_as usuario
    end

    test "exige autenticação" do
      delete sessao_url # desloga o usuário do setup

      get relatorios_titulos_eventuais_path
      assert_redirected_to new_sessao_path
    end

    test "eventuais responde em html e pdf" do
      get relatorios_titulos_eventuais_path
      assert_response :success

      get relatorios_titulos_eventuais_path(format: :pdf)
      assert_response :success
      assert_equal "application/pdf", @response.media_type
    end

    test "por_apresentante sem apresentante_id mostra só o formulário" do
      get relatorios_titulos_por_apresentante_path
      assert_response :success
    end

    test "por_devedor sem cpf_cnpj mostra só o formulário" do
      get relatorios_titulos_por_devedor_path
      assert_response :success
    end
  end
end
