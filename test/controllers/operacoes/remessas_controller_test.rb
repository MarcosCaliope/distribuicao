require "test_helper"

module Operacoes
  class RemessasControllerTest < ActionDispatch::IntegrationTest
    ARQUIVO_VALIDO = Rails.root.join("test/fixtures/files/remessas/banco_brasil_valida.txt")

    setup do
      @apresentante = Apresentante.create!(codigo_legado: "001", nome: "Banco do Brasil", convenio: "B")
      Banco.create!(codigo_legado: "001", nome: "BANCO DO BRASIL SA", apresentante: @apresentante)
      TipoTitulo.create!(codigo_legado: "01", descricao: "Duplicata Mercantil por Indicação", abreviatura: "DMI")

      usuario = Usuario.create!(login: "operador_teste", nome: "Operador", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "operador") ]
      sign_in_as usuario
    end

    test "exige autenticação" do
      delete sessao_url

      get new_operacoes_remessa_path
      assert_redirected_to new_sessao_path
    end

    test "importa um arquivo válido e redireciona com notice" do
      post operacoes_remessas_path, params: {
        arquivo: fixture_file_upload(ARQUIVO_VALIDO, "text/plain")
      }

      assert_redirected_to new_operacoes_remessa_path
      assert_equal 15, Titulo.count
      assert_match(/importada/, flash[:notice])
    end

    test "arquivo inválido redireciona com alert e não grava título nenhum" do
      arquivo_invalido = Tempfile.new
      arquivo_invalido.write("linha curta demais")
      arquivo_invalido.rewind

      post operacoes_remessas_path, params: {
        arquivo: Rack::Test::UploadedFile.new(arquivo_invalido.path, "text/plain")
      }

      assert_redirected_to new_operacoes_remessa_path
      assert flash[:alert].present?
      assert_equal 0, Titulo.count
    ensure
      arquivo_invalido.close!
    end
  end
end
