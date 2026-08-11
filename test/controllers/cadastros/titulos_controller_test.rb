require "test_helper"

module Cadastros
  class TitulosControllerTest < ActionDispatch::IntegrationTest
    setup do
      @devedor = Devedor.create!(tipo_documento: "CNPJ", cpf_cnpj: "07240450000109", nome: "DEVEDOR PRINCIPAL")
      @titulo = Titulo.create!(
        devedor: @devedor, tipo_documento_devedor: "CNPJ", cpf_cnpj_devedor: "07240450000109",
        nome_devedor: "DEVEDOR PRINCIPAL", numero_titulo: "12345", data_recebimento: Date.current, valor: 100
      )
    end

    test "exige autenticação" do
      get cadastros_titulos_path
      assert_redirected_to new_sessao_path
    end

    test "operador sem gerenciar_cadastros não pode acessar" do
      usuario = Usuario.create!(login: "operador_titulos", nome: "Operador", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "operador") ]
      sign_in_as usuario

      assert_raises(Pundit::NotAuthorizedError) { get cadastros_titulos_path }
    end

    test "administrador lista títulos" do
      sign_in_as_administrador

      get cadastros_titulos_path
      assert_response :success
      assert_match "12345", response.body
    end

    test "filtra a lista pelo parâmetro q" do
      sign_in_as_administrador
      Titulo.create!(
        devedor: Devedor.create!(tipo_documento: "CPF", cpf_cnpj: "11111111111", nome: "OUTRO"),
        tipo_documento_devedor: "CPF", cpf_cnpj_devedor: "11111111111",
        nome_devedor: "OUTRO", numero_titulo: "99999", data_recebimento: Date.current, valor: 50
      )

      get cadastros_titulos_path, params: { q: "12345" }
      assert_response :success
      assert_match "12345", response.body
      assert_no_match "99999", response.body
    end

    test "cria título e vincula (ou cria) o devedor pelo cpf_cnpj" do
      sign_in_as_administrador

      assert_difference("Titulo.count", 1) do
        assert_no_difference("Devedor.count") do
          post cadastros_titulos_path, params: {
            titulo: {
              tipo_documento_devedor: "CNPJ", cpf_cnpj_devedor: "07240450000109",
              nome_devedor: "DEVEDOR PRINCIPAL", numero_titulo: "54321", valor: "200.50"
            }
          }
        end
      end
      assert_redirected_to cadastros_titulos_path

      criado = Titulo.order(:created_at).last
      assert_equal @devedor, criado.devedor
      assert_equal "G", criado.status
      assert_equal Date.current, criado.data_recebimento
    end

    test "cria título com devedor novo quando cpf_cnpj não existe" do
      sign_in_as_administrador

      assert_difference("Devedor.count", 1) do
        post cadastros_titulos_path, params: {
          titulo: {
            tipo_documento_devedor: "CPF", cpf_cnpj_devedor: "22222222222",
            nome_devedor: "DEVEDOR NOVO", numero_titulo: "77777", valor: "10"
          }
        }
      end
    end

    test "não cria título inválido e reexibe o form com erro" do
      sign_in_as_administrador

      assert_no_difference("Titulo.count") do
        post cadastros_titulos_path, params: { titulo: { numero_titulo: "" } }
      end
      assert_response :unprocessable_entity
    end

    test "atualiza título" do
      sign_in_as_administrador

      patch cadastros_titulo_path(@titulo), params: { titulo: { numero_titulo: "novo-numero" } }
      assert_redirected_to cadastros_titulos_path
      assert_equal "novo-numero", @titulo.reload.numero_titulo
    end

    test "exclui título não distribuído" do
      sign_in_as_administrador

      assert_difference("Titulo.count", -1) do
        delete cadastros_titulo_path(@titulo)
      end
    end

    test "não exclui título já distribuído" do
      sign_in_as_administrador
      @titulo.update!(data_distribuicao: Date.current)

      assert_no_difference("Titulo.count") do
        delete cadastros_titulo_path(@titulo)
      end
      assert_redirected_to cadastros_titulos_path
    end

    private

    def sign_in_as_administrador
      usuario = Usuario.create!(login: "admin_titulos", nome: "Admin", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "administrador") ]
      sign_in_as usuario
    end
  end
end
