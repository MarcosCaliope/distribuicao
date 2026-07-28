require "test_helper"

module Relatorios
  class ArrecadacaoTotalTitulosTest < ActiveSupport::TestCase
    setup do
      @cartorio = Cartorio.create!(nome: "1º Ofício", codigo_legado: "1")
      @oficio1 = OficioDistribuidor.create!(nome: "1º Distribuidor", codigo_legado: "1")
      @oficio2 = OficioDistribuidor.create!(nome: "2º Distribuidor", codigo_legado: "2")
      @apresentante = Apresentante.create!(nome: "Banco X", codigo_legado: "001")
      @tipo_titulo = TipoTitulo.create!(codigo_legado: "01", descricao: "DMI", abreviatura: "DMI")
      @devedor = Devedor.create!(tipo_documento: "CPF", cpf_cnpj: "11111111111", nome: "DEVEDOR")
      @data = Date.current
    end

    test "conta títulos por ofício e calcula a diferença" do
      3.times { criar_titulo(oficio: @oficio1) }
      1.times { criar_titulo(oficio: @oficio2) }

      dataset = ArrecadacaoTotalTitulos.new(data_inicio: @data, data_fim: @data).gerar

      linha = dataset.linhas.first
      assert_equal 3, linha[1]
      assert_equal 1, linha[2]
      assert_equal 2, linha[3]
    end

    test "uma linha por dia no intervalo, mesmo sem títulos" do
      dataset = ArrecadacaoTotalTitulos.new(data_inicio: 2.days.ago.to_date, data_fim: @data).gerar

      assert_equal 3, dataset.linhas.size
      assert dataset.linhas.all? { |linha| linha[1] == 0 && linha[2] == 0 }
    end

    private

    def criar_titulo(oficio:)
      Titulo.create!(
        devedor: @devedor, tipo_documento_devedor: "CPF", cpf_cnpj_devedor: "11111111111",
        nome_devedor: "DEVEDOR", tipo_titulo: @tipo_titulo, numero_titulo: "T#{SecureRandom.hex(4)}",
        data_recebimento: @data, valor: 100.00, apresentante: @apresentante, cartorio: @cartorio,
        oficio_distribuidor: oficio, data_distribuicao: @data,
        numero_protocolo_distribuido: "1#{SecureRandom.random_number(10**8).to_s.rjust(8, '0')}"
      )
    end
  end
end
