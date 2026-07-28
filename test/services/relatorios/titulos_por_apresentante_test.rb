require "test_helper"

module Relatorios
  class TitulosPorApresentanteTest < ActiveSupport::TestCase
    setup do
      @cartorio1 = Cartorio.create!(nome: "1º Ofício", codigo_legado: "1")
      @cartorio2 = Cartorio.create!(nome: "2º Ofício", codigo_legado: "2")
      @apresentante = Apresentante.create!(nome: "Banco do Brasil", codigo_legado: "001")
      @outro_apresentante = Apresentante.create!(nome: "Caixa", codigo_legado: "002")
      @tipo_titulo = TipoTitulo.create!(codigo_legado: "01", descricao: "DMI", abreviatura: "DMI")
      @devedor = Devedor.create!(tipo_documento: "CPF", cpf_cnpj: "11111111111", nome: "DEVEDOR")
      @data = Date.current
    end

    test "modo detalhe lista um título por linha, só do apresentante escolhido" do
      criar_titulo(apresentante: @apresentante, cartorio: @cartorio1, valor: 100.00)
      criar_titulo(apresentante: @outro_apresentante, cartorio: @cartorio1, valor: 200.00)

      dataset = TitulosPorApresentante.new(
        data_inicio: 10.days.ago.to_date, data_fim: @data, apresentante_id: @apresentante.id
      ).gerar

      assert_equal 1, dataset.linhas.size
    end

    test "modo sintético agrupa por cartório, somando quantidade e valor" do
      criar_titulo(apresentante: @apresentante, cartorio: @cartorio1, valor: 100.00)
      criar_titulo(apresentante: @apresentante, cartorio: @cartorio1, valor: 50.00)
      criar_titulo(apresentante: @apresentante, cartorio: @cartorio2, valor: 30.00)

      dataset = TitulosPorApresentante.new(
        data_inicio: 10.days.ago.to_date, data_fim: @data, apresentante_id: @apresentante.id, sintetico: true
      ).gerar

      assert_equal 2, dataset.linhas.size
      linha_cartorio1 = dataset.linhas.find { |linha| linha.first == @cartorio1.nome }
      assert_equal 2, linha_cartorio1[1]
    end

    private

    def criar_titulo(apresentante:, cartorio:, valor:)
      Titulo.create!(
        devedor: @devedor, tipo_documento_devedor: "CPF", cpf_cnpj_devedor: "11111111111",
        nome_devedor: "DEVEDOR", tipo_titulo: @tipo_titulo, numero_titulo: "T#{SecureRandom.hex(4)}",
        data_recebimento: @data, valor: valor, apresentante: apresentante, cartorio: cartorio,
        data_distribuicao: @data,
        numero_protocolo_distribuido: "1#{SecureRandom.random_number(10**8).to_s.rjust(8, '0')}"
      )
    end
  end
end
