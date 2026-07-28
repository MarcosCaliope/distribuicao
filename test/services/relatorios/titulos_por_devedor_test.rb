require "test_helper"

module Relatorios
  class TitulosPorDevedorTest < ActiveSupport::TestCase
    setup do
      @cartorio = Cartorio.create!(nome: "1º Ofício", codigo_legado: "1")
      @apresentante = Apresentante.create!(nome: "Banco do Brasil", codigo_legado: "001")
      @tipo_titulo = TipoTitulo.create!(codigo_legado: "01", descricao: "DMI", abreviatura: "DMI")
      @devedor = Devedor.create!(tipo_documento: "CPF", cpf_cnpj: "11111111111", nome: "DEVEDOR")
    end

    test "filtra por prefixo do CPF/CNPJ, sem filtro de data" do
      recente = criar_titulo(cpf_cnpj: "11111111111", data_distribuicao: Date.current)
      antigo = criar_titulo(cpf_cnpj: "11111111111", data_distribuicao: 5.years.ago.to_date)
      criar_titulo(cpf_cnpj: "22222222222", data_distribuicao: Date.current)

      dataset = TitulosPorDevedor.new(cpf_cnpj_prefixo: "111").gerar

      protocolos = dataset.linhas.map(&:first)
      assert_includes protocolos, recente.numero_protocolo_distribuido
      assert_includes protocolos, antigo.numero_protocolo_distribuido
      assert_equal 2, dataset.linhas.size
    end

    private

    def criar_titulo(cpf_cnpj:, data_distribuicao:)
      Titulo.create!(
        devedor: @devedor, tipo_documento_devedor: "CPF", cpf_cnpj_devedor: cpf_cnpj,
        nome_devedor: "DEVEDOR", tipo_titulo: @tipo_titulo, numero_titulo: "T#{SecureRandom.hex(4)}",
        data_recebimento: Date.current, valor: 100.00, apresentante: @apresentante, cartorio: @cartorio,
        data_distribuicao: data_distribuicao,
        numero_protocolo_distribuido: "1#{SecureRandom.random_number(10**8).to_s.rjust(8, '0')}"
      )
    end
  end
end
