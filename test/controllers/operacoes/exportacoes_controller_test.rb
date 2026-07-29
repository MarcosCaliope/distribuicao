require "test_helper"

module Operacoes
  class ExportacoesControllerTest < ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper

    setup do
      @cartorio = Cartorio.create!(nome: "1º Ofício", codigo_legado: "1", email: "cartorio@example.com")
      @oficio = OficioDistribuidor.create!(nome: "1º Distribuidor", codigo_legado: "1")
      @apresentante = Apresentante.create!(nome: "Banco do Brasil", codigo_legado: "001")
      @banco = Banco.create!(codigo_legado: "001", nome: "BANCO DO BRASIL", gera_remessa_cartorio: true)
      @remessa = Remessa.create!(
        nome_arquivo: "remessa1.txt", status: "importada", banco: @banco, apresentante: @apresentante,
        numero_remessa: "003333"
      )
      @tipo_titulo = TipoTitulo.create!(codigo_legado: "01", descricao: "Duplicata Mercantil por Indicação", abreviatura: "DMI")
      devedor = Devedor.create!(
        tipo_documento: "CNPJ", cpf_cnpj: "07240450000109", nome: "DEVEDOR PRINCIPAL",
        endereco: "RUA PRINCIPAL, 100", cep: "60000000"
      )
      @data = Date.current
      @titulo = Titulo.create!(
        devedor: devedor,
        tipo_documento_devedor: "CNPJ",
        cpf_cnpj_devedor: "07240450000109",
        nome_devedor: "DEVEDOR PRINCIPAL",
        endereco_devedor: "RUA PRINCIPAL, 100",
        cep_devedor: "60000000",
        tipo_titulo: @tipo_titulo,
        numero_titulo: "T1",
        data_recebimento: @data,
        data_vencimento: 1.month.from_now.to_date,
        valor: 153.30,
        apresentante: @apresentante,
        cartorio: @cartorio,
        oficio_distribuidor: @oficio,
        data_distribuicao: @data,
        remessa: @remessa,
        numero_protocolo_distribuido: "1100000001"
      )

      usuario = Usuario.create!(login: "operador_teste", nome: "Operador", password: SENHA_PADRAO_TESTE)
      usuario.perfis = [ Perfil.find_by!(nome: "operador") ]
      sign_in_as usuario
    end

    test "exige autenticação" do
      delete sessao_url

      get new_operacoes_exportacao_path
      assert_redirected_to new_sessao_path
    end

    test "mostra as quantidades pendentes" do
      get new_operacoes_exportacao_path
      assert_response :success
    end

    test "gera manifesto e retorno e redireciona com notice" do
      perform_enqueued_jobs do
        post operacoes_exportacao_path, params: { data: @data.to_s }
      end

      assert_redirected_to new_operacoes_exportacao_path
      assert_match(/1 manifesto\(s\) e 1 retorno\(s\)/, flash[:notice])
      assert @titulo.reload.manifesto_distribuidor.present?
      assert @titulo.reload.retorno_exportado.present?
    end
  end
end
