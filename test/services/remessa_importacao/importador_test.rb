require "test_helper"

module RemessaImportacao
  class ImportadorTest < ActiveSupport::TestCase
    ARQUIVO_VALIDO = Rails.root.join("test/fixtures/files/remessas/banco_brasil_valida.txt")

    setup do
      @apresentante = Apresentante.create!(codigo_legado: "001", nome: "Banco do Brasil", convenio: "B")
      @banco = Banco.create!(codigo_legado: "001", nome: "BANCO DO BRASIL SA", apresentante: @apresentante)
      @tipo_titulo = TipoTitulo.create!(codigo_legado: "01", descricao: "Duplicata Mercantil por Indicação", abreviatura: "DMI")
    end

    test "importa um arquivo válido, criando remessa, títulos e devedores" do
      remessa = Importador.new(ARQUIVO_VALIDO).importar

      assert_equal "importada", remessa.status
      assert_equal @banco, remessa.banco
      assert_equal @apresentante, remessa.apresentante
      assert_equal "003333", remessa.numero_remessa
      assert_equal 15, remessa.quantidade_titulos
      assert_equal 14, remessa.quantidade_indicacoes
      assert_equal 1, remessa.quantidade_originais
      assert remessa.arquivo.attached?

      assert_equal 15, remessa.titulos.count
      assert_equal 0, DevedorSolidario.count

      titulo = remessa.titulos.find_by(numero_titulo: "0552134N10")
      assert_equal 153.30, titulo.valor
      assert_equal "ANTONIA DO SOCORRO PARENTE AGUIAR 029", titulo.devedor.nome
      assert_equal @tipo_titulo, titulo.tipo_titulo
      assert_nil titulo.irregularidade
      assert_equal Date.current, titulo.data_recebimento
    end

    test "marca como irregular um título cuja espécie não está cadastrada" do
      remessa = Importador.new(ARQUIVO_VALIDO).importar

      irregulares = remessa.titulos.where.not(irregularidade_id: nil)
      assert_equal 1, irregulares.count
      assert_equal 21, irregulares.first.irregularidade.codigo
      assert_nil irregulares.first.tipo_titulo
    end

    test "reaproveita o devedor já cadastrado em vez de duplicar" do
      Importador.new(ARQUIVO_VALIDO).importar

      devedor = Devedor.find_by(cpf_cnpj: "21996051000195")
      assert_not_nil devedor
      assert_equal 1, Devedor.where(cpf_cnpj: "21996051000195").count
    end

    test "recusa reimportar o mesmo arquivo" do
      Importador.new(ARQUIVO_VALIDO).importar

      erro = assert_raises(ErroArquivo) { Importador.new(ARQUIVO_VALIDO).importar }
      assert_match(/já foi importado/, erro.message)
    end

    test "não grava nenhum título quando o banco não está cadastrado" do
      @banco.destroy!

      assert_raises(ErroArquivo) { Importador.new(ARQUIVO_VALIDO).importar }
      assert_equal 0, Titulo.count

      remessa_falha = Remessa.find_by(nome_arquivo: "banco_brasil_valida.txt")
      assert_equal "com_erro", remessa_falha.status
      assert_match(/não cadastrado/, remessa_falha.mensagem_erro)
    end

    test "não grava nenhum título quando o banco não tem apresentante configurado" do
      @banco.update!(apresentante: nil)

      assert_raises(ErroArquivo) { Importador.new(ARQUIVO_VALIDO).importar }
      assert_equal 0, Titulo.count
    end

    test "rejeita arquivo com sequência de linhas incorreta" do
      linhas = File.readlines(ARQUIVO_VALIDO, chomp: true)
      linhas[5] = linhas[5].dup.tap { |l| l[596, 4] = "0099" }
      arquivo_corrompido = Rails.root.join("tmp/remessa_sequencia_invalida.txt")
      File.write(arquivo_corrompido, linhas.join("\r\n"))

      erro = assert_raises(ErroArquivo) { Importador.new(arquivo_corrompido).importar }
      assert_match(/[Ss]equência de linhas/, erro.message)
      assert_equal 0, Titulo.count
    ensure
      File.delete(arquivo_corrompido) if arquivo_corrompido && File.exist?(arquivo_corrompido)
    end

    test "rejeita arquivo com totais do header divergentes da contagem real" do
      linhas = File.readlines(ARQUIVO_VALIDO, chomp: true)
      linhas[0] = linhas[0].dup.tap { |l| l[71, 4] = "0099" } # qtde_titulos header errada
      arquivo_corrompido = Rails.root.join("tmp/remessa_totais_invalidos.txt")
      File.write(arquivo_corrompido, linhas.join("\r\n"))

      erro = assert_raises(ErroArquivo) { Importador.new(arquivo_corrompido).importar }
      assert_match(/quantidade de títulos/, erro.message)
      assert_equal 0, Titulo.count
    ensure
      File.delete(arquivo_corrompido) if arquivo_corrompido && File.exist?(arquivo_corrompido)
    end
  end
end
