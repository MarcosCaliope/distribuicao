ENV["RAILS_ENV"] ||= "test"
# Relatorios::ApplicationController lê essas variáveis uma única vez, no carregamento da
# classe (Zeitwerk) — precisam estar setadas antes do primeiro request que a referencia, daí
# ficarem aqui em vez de num setup de teste.
ENV["RELATORIOS_USUARIO"] ||= "teste"
ENV["RELATORIOS_SENHA"] ||= "teste123"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Dados de referência (ex.: os 70 códigos de Irregularidade) vêm de db/seeds.rb, não de
    # fixtures. Acima de ~50 testes o Rails efetivamente bifurca processos-worker, cada um com
    # sua própria conexão de banco — carregar a seed só uma vez no processo principal (como
    # era antes) nunca chega nos bancos dos workers. `parallelize_setup` roda depois que cada
    # worker já trocou pra sua própria conexão, então é aqui que a seed precisa entrar.
    parallelize_setup do |_worker|
      Rails.application.load_seed
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
