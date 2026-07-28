ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Senha usada por convenção em todo Usuario criado em teste, pra sign_in_as (abaixo) poder
# logar sem precisar saber a senha de cada teste individualmente.
SENHA_PADRAO_TESTE = "senha-de-teste-123"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Dados de referência (ex.: os 70 códigos de Irregularidade, os Perfis/Permissões da Etapa
    # 6) vêm de db/seeds.rb, não de fixtures. Acima de ~50 testes o Rails efetivamente bifurca
    # processos-worker, cada um com sua própria conexão de banco — carregar a seed só uma vez
    # no processo principal (como era antes) nunca chega nos bancos dos workers.
    # `parallelize_setup` roda depois que cada worker já trocou pra sua própria conexão, então
    # é aqui que a seed precisa entrar.
    parallelize_setup do |_worker|
      Rails.application.load_seed
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

# `parallelize_setup` só dispara quando o Rails de fato bifurca workers (suíte inteira, acima
# do limiar de 50 testes) — abaixo disso os testes rodam em série no processo principal e esse
# hook nunca roda. Sem isso aqui, rodar um arquivo de teste isolado (o caso comum no dia a dia)
# ficaria sem nenhuma seed carregada. find_or_create_by! em db/seeds.rb é idempotente, então
# carregar nos dois pontos não duplica nada — só emite um aviso inofensivo de constante
# redefinida quando os dois caminhos rodam no mesmo processo.
Rails.application.load_seed

module ActionDispatch
  class IntegrationTest
    # Loga de verdade via SessoesController#create (não escreve na sessão/cookie por fora) —
    # todo Usuario criado em teste pra isso precisa usar SENHA_PADRAO_TESTE como senha.
    def sign_in_as(usuario)
      post sessao_url, params: { login: usuario.login, password: SENHA_PADRAO_TESTE }
    end
  end
end
