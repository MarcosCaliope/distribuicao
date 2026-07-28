require "test_helper"

module Relatorios
  class RankingDevedoresTest < ActiveSupport::TestCase
    setup do
      @cartorio = Cartorio.create!(nome: "1º Ofício", codigo_legado: "1")
      @apresentante = Apresentante.create!(nome: "Banco X", codigo_legado: "001")
      @tipo_titulo = TipoTitulo.create!(codigo_legado: "01", descricao: "DMI", abreviatura: "DMI")
      @devedor_reincidente = Devedor.create!(tipo_documento: "CPF", cpf_cnpj: "11111111111", nome: "REINCIDENTE")
      @devedor_unico = Devedor.create!(tipo_documento: "CPF", cpf_cnpj: "22222222222", nome: "UNICO")
      @data = Date.current
    end

    test "ordena por quantidade de títulos, decrescente" do
      3.times { criar_titulo(@devedor_reincidente) }
      criar_titulo(@devedor_unico)

      dataset = RankingDevedores.new(data_inicio: 5.days.ago.to_date, data_fim: @data).gerar

      assert_equal "REINCIDENTE", dataset.linhas.first.first
      assert_equal 3, dataset.linhas.first.last
    end

    test "respeita o limite" do
      3.times { criar_titulo(@devedor_reincidente) }
      criar_titulo(@devedor_unico)

      dataset = RankingDevedores.new(data_inicio: 5.days.ago.to_date, data_fim: @data, limite: 1).gerar

      assert_equal 1, dataset.linhas.size
    end

    test "filtra por faixa de quantidade" do
      3.times { criar_titulo(@devedor_reincidente) }
      criar_titulo(@devedor_unico)

      dataset = RankingDevedores.new(data_inicio: 5.days.ago.to_date, data_fim: @data, faixa_minima: 2).gerar

      assert_equal 1, dataset.linhas.size
      assert_equal "REINCIDENTE", dataset.linhas.first.first
    end

    private

    def criar_titulo(devedor)
      Titulo.create!(
        devedor: devedor, tipo_documento_devedor: "CPF", cpf_cnpj_devedor: devedor.cpf_cnpj,
        nome_devedor: devedor.nome, tipo_titulo: @tipo_titulo, numero_titulo: "T#{SecureRandom.hex(4)}",
        data_recebimento: @data, valor: 100.00, apresentante: @apresentante, cartorio: @cartorio,
        data_distribuicao: @data,
        numero_protocolo_distribuido: "1#{SecureRandom.random_number(10**8).to_s.rjust(8, '0')}"
      )
    end
  end
end
