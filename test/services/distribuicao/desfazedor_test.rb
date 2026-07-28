require "test_helper"

module Distribuicao
  class DesfazedorTest < ActiveSupport::TestCase
    setup do
      @cartorio = Cartorio.create!(nome: "1º Ofício", codigo_legado: "1")
      @oficio = OficioDistribuidor.create!(nome: "1º Distribuidor", codigo_legado: "1")
      @devedor = Devedor.create!(tipo_documento: "CPF", cpf_cnpj: "11111111111")
    end

    test "limpa os campos de distribuição só dos títulos da data informada" do
      distribuido_hoje = criar_titulo_distribuido(data_distribuicao: Date.current)
      distribuido_ontem = criar_titulo_distribuido(data_distribuicao: 1.day.ago.to_date)

      Desfazedor.new(Date.current).desfazer!

      distribuido_hoje.reload
      assert_nil distribuido_hoje.cartorio_id
      assert_nil distribuido_hoje.oficio_distribuidor_id
      assert_nil distribuido_hoje.data_distribuicao
      assert_nil distribuido_hoje.numero_protocolo_distribuido

      assert distribuido_ontem.reload.cartorio_id.present?
    end

    test "limpa também os vínculos de exportação (Etapa 4)" do
      titulo = criar_titulo_distribuido(data_distribuicao: Date.current)
      oficio_distribuidor = OficioDistribuidor.find(titulo.oficio_distribuidor_id)
      manifesto = ManifestoDistribuidor.create!(
        oficio_distribuidor: oficio_distribuidor, data: Date.current, quantidade_titulos: 1
      )
      apresentante = Apresentante.create!(nome: "Banco X", codigo_legado: "001")
      retorno = RetornoExportado.create!(
        cartorio: @cartorio, apresentante: apresentante, data: Date.current, quantidade_titulos: 1
      )
      titulo.update!(manifesto_distribuidor: manifesto, retorno_exportado: retorno)

      Desfazedor.new(Date.current).desfazer!

      titulo.reload
      assert_nil titulo.manifesto_distribuidor_id
      assert_nil titulo.retorno_exportado_id
    end

    test "filtra por data_distribuicao, não por data_recebimento (regressão do bug do legado)" do
      titulo = criar_titulo_distribuido(data_distribuicao: 5.days.ago.to_date, data_recebimento: Date.current)

      Desfazedor.new(Date.current).desfazer!

      assert titulo.reload.cartorio_id.present?
    end

    test "não altera o estado de vagas ou ofícios distribuidores" do
      faixa = FaixaCusta.create!(sequencial: 1, tipo: "A", limite_inferior: 0.01, limite_superior: 100.00)
      vaga = VagaDistribuicao.create!(data: Date.current, cartorio: @cartorio, faixa_custa: faixa, livre: false, quantidade_titulos: 1)
      @oficio.update!(livre: false)
      criar_titulo_distribuido(data_distribuicao: Date.current)

      Desfazedor.new(Date.current).desfazer!

      assert_equal false, vaga.reload.livre
      assert_equal false, @oficio.reload.livre
    end

    private

    def criar_titulo_distribuido(data_distribuicao:, data_recebimento: Date.current)
      Titulo.create!(
        devedor: @devedor,
        tipo_documento_devedor: "CPF",
        cpf_cnpj_devedor: "11111111111",
        numero_titulo: "T#{SecureRandom.hex(4)}",
        data_recebimento: data_recebimento,
        valor: 50.00,
        cartorio: @cartorio,
        oficio_distribuidor: @oficio,
        data_distribuicao: data_distribuicao,
        numero_protocolo_distribuido: "P#{SecureRandom.hex(4)}"
      )
    end
  end
end
