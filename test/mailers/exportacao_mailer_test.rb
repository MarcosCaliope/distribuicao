require "test_helper"

class ExportacaoMailerTest < ActionMailer::TestCase
  test "retorno envia para o e-mail do cartório, com cópia e anexo" do
    cartorio = Cartorio.create!(
      nome: "1º Ofício", codigo_legado: "1",
      email: "cartorio@example.com", email_copia: "copia@example.com"
    )
    apresentante = Apresentante.create!(nome: "Banco X", codigo_legado: "001")
    retorno_exportado = RetornoExportado.create!(
      cartorio: cartorio, apresentante: apresentante, data: Date.current, quantidade_titulos: 1
    )
    retorno_exportado.arquivo.attach(
      io: StringIO.new("conteudo"), filename: "retorno.txt", content_type: "text/plain"
    )

    email = ExportacaoMailer.retorno(retorno_exportado)

    assert_equal [ "cartorio@example.com" ], email.to
    assert_equal [ "copia@example.com" ], email.cc
    assert_equal 1, email.attachments.size
    assert_equal "retorno.txt", email.attachments.first.filename
  end

  test "retorno não define cc quando o cartório não tem e-mail de cópia" do
    cartorio = Cartorio.create!(nome: "1º Ofício", codigo_legado: "1", email: "cartorio@example.com")
    apresentante = Apresentante.create!(nome: "Banco X", codigo_legado: "001")
    retorno_exportado = RetornoExportado.create!(
      cartorio: cartorio, apresentante: apresentante, data: Date.current, quantidade_titulos: 1
    )
    retorno_exportado.arquivo.attach(
      io: StringIO.new("conteudo"), filename: "retorno.txt", content_type: "text/plain"
    )

    email = ExportacaoMailer.retorno(retorno_exportado)

    assert_nil email.cc
  end
end
