require "test_helper"

module Operacoes
  class DistribuicoesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @faixa = FaixaCusta.create!(sequencial: 1, tipo: "A", limite_inferior: 0.01, limite_superior: 100.00)
      Cartorio.create!(nome: "1º Ofício", codigo_legado: "1")
      OficioDistribuidor.create!(nome: "1º Distribuidor", codigo_legado: "1")
      OficioDistribuidor.create!(nome: "2º Distribuidor", codigo_legado: "2")
      devedor = Devedor.create!(tipo_documento: "CPF", cpf_cnpj: "11111111111")
      @titulo = Titulo.create!(
        devedor: devedor, tipo_documento_devedor: "CPF", cpf_cnpj_devedor: "11111111111",
        numero_titulo: "1", data_recebimento: Date.current, valor: 50.00
      )

      usuario = Usuario.create!(login: "operador_teste", nome: "Operador", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "operador") ]
      sign_in_as usuario
    end

    test "exige autenticação" do
      delete sessao_url

      get new_operacoes_distribuicao_path
      assert_redirected_to new_sessao_path
    end

    test "mostra a quantidade de títulos pendentes" do
      get new_operacoes_distribuicao_path
      assert_response :success
    end

    test "processa a distribuição do dia e redireciona com notice" do
      post operacoes_distribuicao_path, params: { data: Date.current.to_s }

      assert_redirected_to new_operacoes_distribuicao_path
      assert_match(/concluída sem falhas/, flash[:notice])
      assert @titulo.reload.data_distribuicao.present?
    end

    test "desfaz a distribuição do dia e redireciona com notice" do
      post operacoes_distribuicao_path, params: { data: Date.current.to_s }
      assert @titulo.reload.cartorio.present?

      delete operacoes_distribuicao_path, params: { data: Date.current.to_s }

      assert_redirected_to new_operacoes_distribuicao_path
      assert_match(/desfeita/, flash[:notice])
      @titulo.reload
      assert_nil @titulo.cartorio_id
      assert_nil @titulo.data_distribuicao
    end
  end
end
