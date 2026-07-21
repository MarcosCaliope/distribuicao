require "test_helper"

module RemessaImportacao
  class DetalheTest < ActiveSupport::TestCase
    # Linha real extraída de um arquivo de remessa de produção (D0010706.211),
    # usada para travar o layout de bytes contra dados verdadeiros.
    LINHA = "1001001928637800027APIGUANA MAQUINAS E FERRAMENTAS LTDA         " \
      "APIGUANA MAQUINAS E FERRAMENTAS LTDA         07240450000109" \
      "AV  DUQUE DE CAXIAS 901                      60035111FORTALEZA           " \
      "CE496990000171945DMI0552134N10 11022022220520220010000000001533000000000015330" \
      "FORTALEZA           MN1ANTONIA DO SOCORRO PARENTE AGUIAR 029        " \
      "0012199605100019500000000000SARGENTO JOAO PINHEIRO, 1640.                " \
      "60540513FORTALEZA           CE011106665097 060620220000000000D07062022" \
      "                      0         000000000000000000000000000000000000000" \
      "           0000000000           070620220002".freeze

    setup { @detalhe = Detalhe.new(LINHA) }

    test "campos do cedente e sacador" do
      assert_equal "APIGUANA MAQUINAS E FERRAMENTAS LTDA", @detalhe.nome_cedente
      assert_equal "APIGUANA MAQUINAS E FERRAMENTAS LTDA", @detalhe.nome_sacador
      assert_equal "07240450000109", @detalhe.documento_sacador
      assert_equal "60035111", @detalhe.cep_sacador
      assert_equal "FORTALEZA", @detalhe.cidade_sacador
      assert_equal "CE", @detalhe.uf_sacador
    end

    test "espécie e número do título" do
      assert_equal "DMI", @detalhe.especie
      assert @detalhe.indicacao?
      assert_equal "0552134N10", @detalhe.numero_titulo
    end

    test "datas de emissão e vencimento" do
      assert_equal Date.new(2022, 2, 11), @detalhe.data_emissao
      assert_equal Date.new(2022, 5, 22), @detalhe.data_vencimento
    end

    test "valor em reais a partir dos centavos" do
      assert_equal 153.30, @detalhe.valor
    end

    test "praça de pagamento e flag de devedor principal" do
      assert_equal "FORTALEZA", @detalhe.praca_pagamento
      assert @detalhe.devedor_principal?
    end

    test "campos do devedor" do
      assert_equal "ANTONIA DO SOCORRO PARENTE AGUIAR 029", @detalhe.nome_devedor
      assert_equal "CNPJ", @detalhe.tipo_documento_devedor
      assert_equal "21996051000195", @detalhe.documento_devedor
      assert_equal "SARGENTO JOAO PINHEIRO, 1640.", @detalhe.endereco_devedor
      assert_equal "60540513", @detalhe.cep_devedor
      assert_equal "FORTALEZA", @detalhe.cidade_devedor
      assert_equal "CE", @detalhe.uf_devedor
      assert_equal "", @detalhe.bairro_devedor
    end

    test "efeito falência e sequencial da linha" do
      assert_not @detalhe.efeito_falencia?
      assert_equal 2, @detalhe.numero_sequencial
    end

    test "sentinelas de vencimento à vista e a prazo da vista" do
      linha_a_vista = LINHA.dup
      linha_a_vista[235, 8] = "99999999"
      assert_equal Date.new(2022, 2, 11), Detalhe.new(linha_a_vista).data_vencimento

      linha_1_dia = LINHA.dup
      linha_1_dia[235, 8] = "99990001"
      assert_equal Date.new(2022, 2, 12), Detalhe.new(linha_1_dia).data_vencimento

      linha_30_dias = LINHA.dup
      linha_30_dias[235, 8] = "99990030"
      assert_equal Date.new(2022, 3, 13), Detalhe.new(linha_30_dias).data_vencimento
    end

    test "data inválida retorna nil em vez de levantar erro" do
      linha_invalida = LINHA.dup
      linha_invalida[227, 8] = "99999999" # não é um sentinela de vencimento, é data de emissão
      linha_invalida[227, 8] = "32131900"
      assert_nil Detalhe.new(linha_invalida).data_emissao
    end
  end
end
