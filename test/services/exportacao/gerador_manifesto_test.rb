require "test_helper"

module Exportacao
  class GeradorManifestoTest < ActiveSupport::TestCase
    setup do
      @cartorio = Cartorio.create!(nome: "1º Ofício", codigo_legado: "1")
      @oficio1 = OficioDistribuidor.create!(nome: "1º Distribuidor", codigo_legado: "1")
      @oficio2 = OficioDistribuidor.create!(nome: "2º Distribuidor", codigo_legado: "2")
      @apresentante = Apresentante.create!(nome: "Banco do Brasil", codigo_legado: "001")
      @tipo_titulo = TipoTitulo.create!(codigo_legado: "01", descricao: "Duplicata Mercantil por Indicação", abreviatura: "DMI")
      @devedor = Devedor.create!(
        tipo_documento: "CNPJ", cpf_cnpj: "07240450000109", nome: "DEVEDOR PRINCIPAL",
        endereco: "RUA PRINCIPAL, 100", cep: "60000000"
      )
      @data = Date.current
    end

    test "gera uma linha de 304 bytes por título, com os campos nas posições certas" do
      titulo = criar_titulo(valor: 153.30)

      manifestos = GeradorManifesto.new(data: @data).gerar

      assert_equal 1, manifestos.size
      manifesto = manifestos.first
      assert_equal @oficio1, manifesto.oficio_distribuidor
      assert_equal 1, manifesto.quantidade_titulos
      assert manifesto.arquivo.attached?

      linha = manifesto.arquivo.download
      assert_equal 306, linha.bytesize # 304 + CRLF

      assert_equal "CNPJ", linha[0, 4].strip
      assert_equal "07240450000109", linha[4, 14].strip
      assert_equal "DMI", linha[18, 3].strip
      assert_equal titulo.numero_titulo, linha[21, 15].strip
      assert_equal titulo.data_vencimento.strftime("%d%m%Y"), linha[36, 8]
      assert_equal titulo.data_recebimento.strftime("%d%m%Y"), linha[44, 8]
      assert_equal "00000000015330", linha[52, 14]
      assert_equal @data.strftime("%d%m%Y"), linha[66, 8]
      assert_equal "1", linha[74, 1]
      assert_equal "001", linha[75, 6].strip
      assert_equal "Banco do Brasil", linha[81, 45].strip
      assert_equal "DEVEDOR PRINCIPAL", linha[126, 50].strip
      assert_equal "1", linha[176, 1]
      assert_equal titulo.numero_protocolo_distribuido, linha[189, 10]
      assert_equal "1", linha[244, 1]
      assert_equal "RUA PRINCIPAL, 100", linha[245, 50].strip
      assert_equal "60000000", linha[295, 8].strip
      assert_equal " ", linha[303, 1]

      titulo.reload
      assert_equal manifesto, titulo.manifesto_distribuidor
    end

    test "não trava com data_vencimento nula (bug do legado não replicado)" do
      criar_titulo(valor: 100.00, data_vencimento: nil)

      manifestos = GeradorManifesto.new(data: @data).gerar

      linha = manifestos.first.arquivo.download
      assert_equal " " * 8, linha[36, 8]
    end

    test "gera uma linha extra por codevedor, com a posição incrementando a partir de 2" do
      titulo = criar_titulo(valor: 100.00)
      outro_devedor = Devedor.create!(
        tipo_documento: "CPF", cpf_cnpj: "11111111111", nome: "CODEVEDOR",
        endereco: "RUA DO CODEVEDOR, 50", cep: "60111000"
      )
      DevedorSolidario.create!(titulo: titulo, devedor: outro_devedor)

      manifestos = GeradorManifesto.new(data: @data).gerar

      conteudo = manifestos.first.arquivo.download
      linhas = conteudo.split("\r\n")
      assert_equal 2, linhas.size
      assert_equal "2", linhas[1][244, 1]
      assert_equal "CODEVEDOR", linhas[1][126, 50].strip
    end

    test "não inclui título já exportado num manifesto anterior" do
      titulo = criar_titulo(valor: 100.00)
      GeradorManifesto.new(data: @data).gerar
      assert titulo.reload.manifesto_distribuidor_id.present?

      assert_no_difference "ManifestoDistribuidor.count" do
        manifestos = GeradorManifesto.new(data: @data).gerar
        assert_empty manifestos
      end
    end

    test "pula um ofício sem títulos pendentes em vez de abortar o lote (bug do legado não replicado)" do
      criar_titulo(valor: 100.00, oficio_distribuidor: @oficio1)

      manifestos = GeradorManifesto.new(data: @data).gerar

      assert_equal 1, manifestos.size
      assert_equal @oficio1, manifestos.first.oficio_distribuidor
    end

    test "exclui títulos com espécie não cadastrada (tipo_titulo_id nulo)" do
      criar_titulo(valor: 100.00, tipo_titulo: nil)

      manifestos = GeradorManifesto.new(data: @data).gerar

      assert_empty manifestos
    end

    private

    def criar_titulo(valor:, oficio_distribuidor: @oficio1, tipo_titulo: @tipo_titulo, data_vencimento: 1.month.from_now.to_date)
      Titulo.create!(
        devedor: @devedor,
        tipo_documento_devedor: "CNPJ",
        cpf_cnpj_devedor: "07240450000109",
        nome_devedor: "DEVEDOR PRINCIPAL",
        endereco_devedor: "RUA PRINCIPAL, 100",
        cep_devedor: "60000000",
        tipo_titulo: tipo_titulo,
        numero_titulo: "T#{SecureRandom.hex(4)}",
        data_recebimento: @data,
        data_vencimento: data_vencimento,
        valor: valor,
        apresentante: @apresentante,
        cartorio: @cartorio,
        oficio_distribuidor: oficio_distribuidor,
        data_distribuicao: @data,
        numero_protocolo_distribuido: "1#{oficio_distribuidor&.codigo_legado || 1}#{SecureRandom.random_number(10**8).to_s.rjust(8, '0')}"
      )
    end
  end
end
