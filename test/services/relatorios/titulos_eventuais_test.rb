require "test_helper"

module Relatorios
  class TitulosEventuaisTest < ActiveSupport::TestCase
    setup do
      @cartorio = Cartorio.create!(nome: "1º Ofício", codigo_legado: "1")
      @apresentante = Apresentante.create!(nome: "Banco do Brasil", codigo_legado: "001")
      @tipo_titulo = TipoTitulo.create!(codigo_legado: "01", descricao: "DMI", abreviatura: "DMI")
      @devedor = Devedor.create!(tipo_documento: "CPF", cpf_cnpj: "11111111111", nome: "DEVEDOR")
      @data = Date.current
    end

    test "inclui só títulos distribuídos com status G no período" do
      elegivel = criar_titulo(status: "G", data_distribuicao: @data)
      criar_titulo(status: "", data_distribuicao: @data) # status vazio, como o import grava hoje
      criar_titulo(status: "G", data_distribuicao: 60.days.ago.to_date) # fora do período

      dataset = TitulosEventuais.new(data_inicio: 10.days.ago.to_date, data_fim: @data).gerar

      assert_equal 1, dataset.linhas.size
      assert_equal elegivel.numero_protocolo_distribuido, dataset.linhas.first.first
    end

    test "filtra por prefixo do nome do apresentante" do
      criar_titulo(status: "G", data_distribuicao: @data)

      dataset = TitulosEventuais.new(data_inicio: 10.days.ago.to_date, data_fim: @data, apresentante_prefixo: "Caixa").gerar

      assert_empty dataset.linhas
    end

    test "exclui títulos com espécie não cadastrada" do
      criar_titulo(status: "G", data_distribuicao: @data, tipo_titulo: nil)

      dataset = TitulosEventuais.new(data_inicio: 10.days.ago.to_date, data_fim: @data).gerar

      assert_empty dataset.linhas
    end

    private

    def criar_titulo(status:, data_distribuicao:, tipo_titulo: @tipo_titulo)
      Titulo.create!(
        devedor: @devedor, tipo_documento_devedor: "CPF", cpf_cnpj_devedor: "11111111111",
        nome_devedor: "DEVEDOR", tipo_titulo: tipo_titulo, numero_titulo: "T#{SecureRandom.hex(4)}",
        data_recebimento: @data, valor: 100.00, apresentante: @apresentante, cartorio: @cartorio,
        status: status, data_distribuicao: data_distribuicao,
        numero_protocolo_distribuido: "1#{SecureRandom.random_number(10**8).to_s.rjust(8, '0')}"
      )
    end
  end
end
