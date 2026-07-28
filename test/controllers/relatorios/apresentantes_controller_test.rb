require "test_helper"

module Relatorios
  class ApresentantesControllerTest < ActionDispatch::IntegrationTest
    test "exige autenticação e responde em html e pdf" do
      get relatorios_apresentantes_path
      assert_redirected_to new_sessao_path

      usuario = Usuario.create!(login: "operador_teste", nome: "Operador", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "operador") ]
      sign_in_as usuario

      get relatorios_apresentantes_path
      assert_response :success

      get relatorios_apresentantes_path(format: :pdf)
      assert_response :success
    end
  end
end
