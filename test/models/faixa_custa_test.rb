require "test_helper"

class FaixaCustaTest < ActiveSupport::TestCase
  test "scope ativos retorna só faixas de custa ativas" do
    ativa = FaixaCusta.create!(sequencial: 1, tipo: "A", limite_inferior: 0, limite_superior: 100)
    inativa = FaixaCusta.create!(sequencial: 2, tipo: "B", limite_inferior: 100, limite_superior: 200).tap(&:inativar!)

    assert_includes FaixaCusta.ativos, ativa
    assert_not_includes FaixaCusta.ativos, inativa
  end

  test "inativar! desativa sem apagar a linha" do
    faixa_custa = FaixaCusta.create!(sequencial: 1, tipo: "A", limite_inferior: 0, limite_superior: 100)

    assert_difference("FaixaCusta.count", 0) { faixa_custa.inativar! }
    assert_not faixa_custa.ativo
  end

  test "exige tipo" do
    faixa_custa = FaixaCusta.new(sequencial: 1, limite_inferior: 0, limite_superior: 100)

    assert_not faixa_custa.valid?
  end

  test "várias faixas podem compartilhar o mesmo tipo" do
    FaixaCusta.create!(sequencial: 1, tipo: "A", limite_inferior: 0, limite_superior: 100)
    outra = FaixaCusta.new(sequencial: 2, tipo: "A", limite_inferior: 100, limite_superior: 200)

    assert outra.valid?
  end
end
