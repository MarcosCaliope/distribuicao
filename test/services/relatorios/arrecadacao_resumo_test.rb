require "test_helper"

module Relatorios
  class ArrecadacaoResumoTest < ActiveSupport::TestCase
    setup do
      @cartorio = Cartorio.create!(nome: "1º Ofício", codigo_legado: "1")
      @oficio = OficioDistribuidor.create!(nome: "1º Distribuidor", codigo_legado: "1")
      @apresentante_cda = Apresentante.create!(nome: "CDA", codigo_legado: "001", convenio: "C")
      @apresentante_banco = Apresentante.create!(nome: "Banco X", codigo_legado: "002", convenio: "B")
      @tipo_titulo = TipoTitulo.create!(codigo_legado: "01", descricao: "DMI", abreviatura: "DMI")
      @devedor = Devedor.create!(tipo_documento: "CPF", cpf_cnpj: "11111111111", nome: "DEVEDOR")
      @data = Date.current
    end

    test "agrupa por data, ofício e convênio" do
      criar_titulo(apresentante: @apresentante_cda)
      criar_titulo(apresentante: @apresentante_cda)
      criar_titulo(apresentante: @apresentante_banco)

      dataset = ArrecadacaoResumo.new(data_inicio: 5.days.ago.to_date, data_fim: @data).gerar

      linha_cda = dataset.linhas.find { |linha| linha[2] == "CDA" }
      linha_banco = dataset.linhas.find { |linha| linha[2] == "Banco" }
      assert_equal 2, linha_cda.last
      assert_equal 1, linha_banco.last
    end

    private

    def criar_titulo(apresentante:)
      Titulo.create!(
        devedor: @devedor, tipo_documento_devedor: "CPF", cpf_cnpj_devedor: "11111111111",
        nome_devedor: "DEVEDOR", tipo_titulo: @tipo_titulo, numero_titulo: "T#{SecureRandom.hex(4)}",
        data_recebimento: @data, valor: 100.00, apresentante: apresentante, cartorio: @cartorio,
        oficio_distribuidor: @oficio, data_distribuicao: @data,
        numero_protocolo_distribuido: "1#{SecureRandom.random_number(10**8).to_s.rjust(8, '0')}"
      )
    end
  end
end
