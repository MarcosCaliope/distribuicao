require "test_helper"

module Operacoes
  class ValidacoesSombraControllerTest < ActionDispatch::IntegrationTest
    setup do
      usuario = Usuario.create!(login: "operador_teste", nome: "Operador", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "operador") ]
      sign_in_as usuario
    end

    test "exige autenticação" do
      delete sessao_url

      get operacoes_validacoes_sombra_path
      assert_redirected_to new_sessao_path
    end

    test "lista execuções existentes, mais recente primeiro" do
      ValidacaoSombraExecucao.create!(
        data_inicio: Date.new(2026, 1, 1), data_fim: Date.new(2026, 1, 1),
        arquivos_processados: 5, titulos_comparados: 100, titulos_batendo: 100
      )
      ValidacaoSombraExecucao.create!(
        data_inicio: Date.new(2026, 1, 2), data_fim: Date.new(2026, 1, 2),
        arquivos_processados: 3, titulos_comparados: 50, titulos_batendo: 48
      )

      get operacoes_validacoes_sombra_path
      assert_response :success

      corpo = @response.body
      assert corpo.index("2026-01-02") < corpo.index("2026-01-01")
    end

    test "sem execuções mostra mensagem" do
      get operacoes_validacoes_sombra_path
      assert_response :success
      assert_match(/Nenhuma execução registrada/, @response.body)
    end
  end
end
