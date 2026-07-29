require "test_helper"

module Cadastros
  class TipoTitulosControllerTest < ActionDispatch::IntegrationTest
    setup do
      @tipo_titulo = TipoTitulo.create!(codigo_legado: "01", descricao: "Duplicata Mercantil", abreviatura: "DM")
    end

    test "exige autenticação" do
      get cadastros_tipo_titulos_path
      assert_redirected_to new_sessao_path
    end

    test "operador sem gerenciar_cadastros não pode acessar" do
      usuario = Usuario.create!(login: "operador_tipos", nome: "Operador", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "operador") ]
      sign_in_as usuario

      assert_raises(Pundit::NotAuthorizedError) { get cadastros_tipo_titulos_path }
    end

    test "administrador lista tipos de título ativos e inativos" do
      sign_in_as_administrador
      TipoTitulo.create!(codigo_legado: "02", descricao: "Inativo", abreviatura: "INA").inativar!

      get cadastros_tipo_titulos_path
      assert_response :success
    end

    test "cria tipo de título" do
      sign_in_as_administrador

      assert_difference("TipoTitulo.count", 1) do
        post cadastros_tipo_titulos_path, params: { tipo_titulo: { codigo_legado: "03", descricao: "Cheque", abreviatura: "CH" } }
      end
      assert_redirected_to cadastros_tipo_titulos_path
    end

    test "não cria tipo de título inválido e reexibe o form com erro" do
      sign_in_as_administrador

      assert_no_difference("TipoTitulo.count") do
        post cadastros_tipo_titulos_path, params: { tipo_titulo: { descricao: "" } }
      end
      assert_response :unprocessable_entity
    end

    test "atualiza tipo de título" do
      sign_in_as_administrador

      patch cadastros_tipo_titulo_path(@tipo_titulo), params: { tipo_titulo: { descricao: "Novo nome" } }
      assert_redirected_to cadastros_tipo_titulos_path
      assert_equal "Novo nome", @tipo_titulo.reload.descricao
    end

    test "destroy inativa em vez de apagar a linha" do
      sign_in_as_administrador

      assert_no_difference("TipoTitulo.count") do
        delete cadastros_tipo_titulo_path(@tipo_titulo)
      end
      assert_not @tipo_titulo.reload.ativo
    end

    private

    def sign_in_as_administrador
      usuario = Usuario.create!(login: "admin_tipos", nome: "Admin", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "administrador") ]
      sign_in_as usuario
    end
  end
end
