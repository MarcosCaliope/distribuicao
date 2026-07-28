require "test_helper"

module Distribuicao
  class RodizioOficioTest < ActiveSupport::TestCase
    setup do
      @oficio1 = OficioDistribuidor.create!(nome: "1º Distribuidor", codigo_legado: "1")
      @oficio2 = OficioDistribuidor.create!(nome: "2º Distribuidor", codigo_legado: "2")
    end

    test "alterna estritamente entre os ofícios, resetando quando ambos ocupados" do
      primeiro = RodizioOficio.reservar!
      segundo = RodizioOficio.reservar!

      assert_not_equal primeiro, segundo
      assert_equal 2, OficioDistribuidor.where(livre: false).count

      terceiro = RodizioOficio.reservar!
      assert_equal primeiro, terceiro
    end

    test "levanta erro quando não há ofício cadastrado" do
      OficioDistribuidor.delete_all

      assert_raises(ErroDistribuicao) { RodizioOficio.reservar! }
    end
  end
end
