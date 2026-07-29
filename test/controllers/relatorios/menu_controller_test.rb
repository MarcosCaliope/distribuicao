require "test_helper"

module Relatorios
  class MenuControllerTest < ActionDispatch::IntegrationTest
    setup do
      usuario = Usuario.create!(login: "operador_teste", nome: "Operador", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "operador") ]
      sign_in_as usuario
    end

    test "exige autenticação" do
      delete sessao_url

      get relatorios_menu_path
      assert_redirected_to new_sessao_path
    end

    test "lista um link para cada relatório" do
      get relatorios_menu_path
      assert_response :success

      assert_select "a[href=?]", relatorios_titulos_eventuais_path
      assert_select "a[href=?]", relatorios_titulos_por_apresentante_path
      assert_select "a[href=?]", relatorios_titulos_por_devedor_path
      assert_select "a[href=?]", relatorios_arrecadacao_resumo_path
      assert_select "a[href=?]", relatorios_arrecadacao_total_titulos_path
      assert_select "a[href=?]", relatorios_ranking_devedores_path
      assert_select "a[href=?]", relatorios_apresentantes_path
    end

    test "raiz do app serve o mesmo menu de relatórios" do
      get root_path
      assert_response :success
      assert_select "a[href=?]", relatorios_titulos_eventuais_path
    end

    test "login sem destino prévio cai no menu de relatórios" do
      delete sessao_url

      post sessao_url, params: { login: "operador_teste", password: SENHA_PADRAO_TESTE }
      assert_redirected_to relatorios_menu_path
    end
  end
end
