require "test_helper"

module Distribuicao
  class SorteioCartorioTest < ActiveSupport::TestCase
    setup do
      @faixa = FaixaCusta.create!(sequencial: 1, tipo: "A", limite_inferior: 0.01, limite_superior: 100.00)
      @cartorio1 = Cartorio.create!(nome: "1º Ofício", codigo_legado: "1")
      @cartorio2 = Cartorio.create!(nome: "2º Ofício", codigo_legado: "2")
      @data = Date.current
      VagaDistribuicao.create!(data: @data, cartorio: @cartorio1, faixa_custa: @faixa, livre: true)
      VagaDistribuicao.create!(data: @data, cartorio: @cartorio2, faixa_custa: @faixa, livre: true)
    end

    test "reserva uma vaga livre e incrementa o contador" do
      cartorio = SorteioCartorio.reservar!(data: @data, faixa_custa: @faixa)

      assert_includes [ @cartorio1, @cartorio2 ], cartorio
      vaga = VagaDistribuicao.find_by(cartorio: cartorio, faixa_custa: @faixa, data: @data)
      assert_not vaga.livre
      assert_equal 1, vaga.quantidade_titulos
    end

    test "reseta a faixa inteira quando todas as vagas estão ocupadas" do
      SorteioCartorio.reservar!(data: @data, faixa_custa: @faixa)
      SorteioCartorio.reservar!(data: @data, faixa_custa: @faixa)
      assert_equal 0, VagaDistribuicao.where(data: @data, faixa_custa: @faixa, livre: true).count

      terceiro = SorteioCartorio.reservar!(data: @data, faixa_custa: @faixa)

      vagas = VagaDistribuicao.where(data: @data, faixa_custa: @faixa)
      assert_equal 1, vagas.where(livre: false).count
      assert_equal terceiro, vagas.find_by(livre: false).cartorio
    end

    test "levanta erro quando não há vaga cadastrada para a faixa" do
      outra_faixa = FaixaCusta.create!(sequencial: 2, tipo: "B", limite_inferior: 100.01, limite_superior: 200.00)

      assert_raises(ErroDistribuicao) do
        SorteioCartorio.reservar!(data: @data, faixa_custa: outra_faixa)
      end
    end
  end
end
