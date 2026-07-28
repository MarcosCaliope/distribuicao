require "test_helper"

module Distribuicao
  class ProcessadorTest < ActiveSupport::TestCase
    setup do
      @faixa_a = FaixaCusta.create!(sequencial: 1, tipo: "A", limite_inferior: 0.01, limite_superior: 100.00)
      @faixa_b = FaixaCusta.create!(sequencial: 2, tipo: "B", limite_inferior: 100.01, limite_superior: 500.00)
      @cartorio = Cartorio.create!(nome: "1º Ofício", codigo_legado: "1")
      @oficio1 = OficioDistribuidor.create!(nome: "1º Distribuidor", codigo_legado: "1")
      @oficio2 = OficioDistribuidor.create!(nome: "2º Distribuidor", codigo_legado: "2")
      @devedor = Devedor.create!(tipo_documento: "CPF", cpf_cnpj: "11111111111")
    end

    test "distribui um título pendente, preenchendo cartório, ofício, data e protocolo" do
      titulo = criar_titulo(valor: 50.00)

      falhas = Processador.new(data: Date.current).processar

      assert_empty falhas
      titulo.reload
      assert_equal @cartorio, titulo.cartorio
      assert_includes [ @oficio1, @oficio2 ], titulo.oficio_distribuidor
      assert_equal Date.current, titulo.data_distribuicao
      esperado = "#{@cartorio.codigo_legado}#{titulo.oficio_distribuidor.codigo_legado}#{titulo.id.to_s.rjust(8, '0')}"
      assert_equal esperado, titulo.numero_protocolo_distribuido
    end

    test "roteia títulos para a faixa correta, inclusive nos limites" do
      no_limite_a = criar_titulo(valor: @faixa_a.limite_superior)
      no_limite_b = criar_titulo(valor: @faixa_b.limite_inferior)

      falhas = Processador.new(data: Date.current).processar

      assert_empty falhas
      vaga_a = VagaDistribuicao.find_by(data: Date.current, faixa_custa: @faixa_a)
      vaga_b = VagaDistribuicao.find_by(data: Date.current, faixa_custa: @faixa_b)
      assert_equal 1, vaga_a.quantidade_titulos
      assert_equal 1, vaga_b.quantidade_titulos
      assert no_limite_a.reload.data_distribuicao.present?
      assert no_limite_b.reload.data_distribuicao.present?
    end

    test "registra falha sem interromper o lote quando um título não tem faixa correspondente" do
      sem_faixa = criar_titulo(valor: 1000.00)
      com_faixa = criar_titulo(valor: 50.00)

      falhas = Processador.new(data: Date.current).processar

      assert_equal 1, falhas.size
      assert_equal sem_faixa, falhas.first.titulo
      assert_nil sem_faixa.reload.data_distribuicao
      assert com_faixa.reload.data_distribuicao.present?
    end

    test "pendentes_distribuicao chega a zero após um lote completo" do
      3.times { criar_titulo(valor: 50.00) }

      Processador.new(data: Date.current).processar

      assert_equal 0, Titulo.pendentes_distribuicao.count
    end

    test "rodar duas vezes na mesma data não recria vagas" do
      criar_titulo(valor: 50.00)
      Processador.new(data: Date.current).processar
      total_vagas = VagaDistribuicao.count

      Processador.new(data: Date.current).processar

      assert_equal total_vagas, VagaDistribuicao.count
    end

    private

    def criar_titulo(valor:)
      Titulo.create!(
        devedor: @devedor,
        tipo_documento_devedor: "CPF",
        cpf_cnpj_devedor: "11111111111",
        numero_titulo: "T#{SecureRandom.hex(4)}",
        data_recebimento: Date.current,
        valor: valor
      )
    end
  end
end
