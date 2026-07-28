require "test_helper"

module Exportacao
  class EnvioRetornoJobTest < ActiveJob::TestCase
    setup do
      @cartorio = Cartorio.create!(nome: "1º Ofício", codigo_legado: "1", email: "cartorio@example.com")
      @apresentante = Apresentante.create!(nome: "Banco X", codigo_legado: "001")
      @retorno_exportado = RetornoExportado.create!(
        cartorio: @cartorio, apresentante: @apresentante, data: Date.current, quantidade_titulos: 1
      )
      @retorno_exportado.arquivo.attach(
        io: StringIO.new("conteudo"), filename: "retorno.txt", content_type: "text/plain"
      )
    end

    test "entrega o e-mail e marca enviado_em" do
      assert_difference "ActionMailer::Base.deliveries.size", 1 do
        EnvioRetornoJob.perform_now(@retorno_exportado.id)
      end

      assert @retorno_exportado.reload.enviado_em.present?
    end
  end
end
