require "test_helper"

module Exportacao
  class GeradorRetornoTest < ActiveSupport::TestCase
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
      @irregularidade = Irregularidade.find_by!(codigo: 7)
      @devedor = Devedor.create!(
        tipo_documento: "CNPJ", cpf_cnpj: "07240450000109", nome: "DEVEDOR PRINCIPAL",
        endereco: "RUA PRINCIPAL, 100", cep: "60000000"
      )
      @data = Date.current
    end

    test "gera um arquivo de 600 bytes por linha, agrupado por cartório+apresentante" do
      titulo = criar_titulo(valor: 153.30)

      retornos = GeradorRetorno.new(data: @data).gerar

      assert_equal 1, retornos.size
      retorno = retornos.first
      assert_equal @cartorio, retorno.cartorio
      assert_equal @apresentante, retorno.apresentante
      assert_equal 1, retorno.quantidade_titulos
      assert retorno.arquivo.attached?

      conteudo = retorno.arquivo.download
      linhas = conteudo.split("\r\n")
      assert_equal 3, linhas.size # header + 1 detalhe + trailer
      assert_equal 600, linhas[0].bytesize
      assert_equal 600, linhas[1].bytesize
      assert_equal 600, linhas[2].bytesize

      header = linhas[0]
      assert_equal "0", header[0, 1]
      assert_equal "001", header[1, 3].strip
      assert_equal "003333", header[61, 6].strip
      assert_equal "0001", header[67, 4] # registros: 1 detalhe
      assert_equal "0001", header[71, 4] # titulos
      assert_equal "0001", header[75, 4] # indicações (DMI)
      assert_equal "0000", header[79, 4] # originais

      detalhe = linhas[1]
      assert_equal "1", detalhe[0, 1]
      assert_equal "001", detalhe[1, 3].strip
      assert_equal "DMI", detalhe[213, 3].strip
      assert_equal titulo.numero_titulo, detalhe[216, 11].strip
      assert_equal "00000000015330", detalhe[246, 14]
      assert_equal "00000000015330", detalhe[260, 14]
      assert_equal "1", detalhe[296, 1] # devedor principal
      assert_equal "DEVEDOR PRINCIPAL", detalhe[297, 45].strip
      assert_equal "001", detalhe[342, 3] # CNPJ -> 001
      assert_equal "07240450000109", detalhe[345, 14].strip
      assert_equal "RUA PRINCIPAL, 100", detalhe[370, 45].strip
      assert_equal "60000000", detalhe[415, 8].strip
      # bloco de ocorrência (445-486)
      assert_equal "1", detalhe[445, 2].strip
      assert_equal titulo.numero_protocolo_distribuido, detalhe[447, 10]
      assert_equal "07", detalhe[485, 2]
      assert_equal " ", detalhe[565, 1] # sem efeito de falência
      assert_equal "0001", detalhe[596, 4] # numero_sequencial

      trailer = linhas[2]
      assert_equal "9", trailer[0, 1]
      assert_equal "00001", trailer[52, 5]
      assert_equal "000000000000015330", trailer[57, 18]

      titulo.reload
      assert_equal retorno, titulo.retorno_exportado
    end

    test "enfileira o job de envio para cada retorno gerado" do
      criar_titulo(valor: 100.00)

      assert_enqueued_with(job: EnvioRetornoJob) do
        GeradorRetorno.new(data: @data).gerar
      end
    end

    test "não inclui títulos de banco com gera_remessa_cartorio desligado" do
      @banco.update!(gera_remessa_cartorio: false)
      criar_titulo(valor: 100.00)

      retornos = GeradorRetorno.new(data: @data).gerar

      assert_empty retornos
    end

    test "não inclui título já exportado num retorno anterior" do
      titulo = criar_titulo(valor: 100.00)
      GeradorRetorno.new(data: @data).gerar
      assert titulo.reload.retorno_exportado_id.present?

      assert_no_difference "RetornoExportado.count" do
        assert_empty GeradorRetorno.new(data: @data).gerar
      end
    end

    test "gera uma linha extra por codevedor, com o flag de devedor principal zerado" do
      titulo = criar_titulo(valor: 100.00)
      outro_devedor = Devedor.create!(
        tipo_documento: "CPF", cpf_cnpj: "11111111111", nome: "CODEVEDOR",
        endereco: "RUA DO CODEVEDOR, 50", cep: "60111000"
      )
      DevedorSolidario.create!(titulo: titulo, devedor: outro_devedor)

      retornos = GeradorRetorno.new(data: @data).gerar

      linhas = retornos.first.arquivo.download.split("\r\n")
      assert_equal 4, linhas.size # header + 2 detalhe + trailer
      assert_equal "0", linhas[2][296, 1]
      assert_equal "CODEVEDOR", linhas[2][297, 45].strip
      assert_equal "0002", linhas[2][596, 4]
    end

    private

    def criar_titulo(valor:)
      Titulo.create!(
        devedor: @devedor,
        tipo_documento_devedor: "CNPJ",
        cpf_cnpj_devedor: "07240450000109",
        nome_devedor: "DEVEDOR PRINCIPAL",
        endereco_devedor: "RUA PRINCIPAL, 100",
        cep_devedor: "60000000",
        tipo_titulo: @tipo_titulo,
        numero_titulo: "T#{SecureRandom.hex(4)}",
        data_recebimento: @data,
        data_vencimento: 1.month.from_now.to_date,
        valor: valor,
        apresentante: @apresentante,
        cartorio: @cartorio,
        oficio_distribuidor: @oficio,
        data_distribuicao: @data,
        remessa: @remessa,
        irregularidade: @irregularidade,
        numero_protocolo_distribuido: "11#{SecureRandom.random_number(10**8).to_s.rjust(8, '0')}"
      )
    end
  end
end
