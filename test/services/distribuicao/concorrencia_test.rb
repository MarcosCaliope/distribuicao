require "test_helper"

module Distribuicao
  # self.use_transactional_tests = false: precisa de conexões e transações reais e
  # concorrentes (o próprio ponto do teste), não da transação única por teste que o
  # Rails normalmente usa para dar rollback automático. Limpeza feita manualmente.
  class ConcorrenciaTest < ActiveSupport::TestCase
    self.use_transactional_tests = false

    NUM_THREADS = 4

    setup do
      @faixa = FaixaCusta.create!(sequencial: 1, tipo: "A", limite_inferior: 0.01, limite_superior: 100.00)
      @cartorio1 = Cartorio.create!(nome: "1º Ofício", codigo_legado: "1")
      @cartorio2 = Cartorio.create!(nome: "2º Ofício", codigo_legado: "2")
      @data = Date.current
      VagaDistribuicao.create!(data: @data, cartorio: @cartorio1, faixa_custa: @faixa, livre: true)
      VagaDistribuicao.create!(data: @data, cartorio: @cartorio2, faixa_custa: @faixa, livre: true)
    end

    teardown do
      VagaDistribuicao.where(data: @data, faixa_custa: @faixa).delete_all
      Cartorio.where(id: [ @cartorio1.id, @cartorio2.id ]).delete_all
      FaixaCusta.where(id: @faixa.id).delete_all
    end

    test "reservas concorrentes na mesma faixa não perdem atualizações" do
      threads = Array.new(NUM_THREADS) do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            SorteioCartorio.reservar!(data: @data, faixa_custa: @faixa)
          end
        end
      end
      resultados = threads.map(&:value)

      assert_equal NUM_THREADS, resultados.compact.size
      total = VagaDistribuicao.where(data: @data, faixa_custa: @faixa).sum(:quantidade_titulos)
      assert_equal NUM_THREADS, total
    end
  end
end
