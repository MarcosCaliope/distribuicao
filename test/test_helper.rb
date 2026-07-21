ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

# Dados de referência (ex.: os 70 códigos de Irregularidade) vêm de
# db/seeds.rb, não de fixtures — carregado uma vez por processo de teste,
# antes de cada teste começar sua própria transação.
Rails.application.load_seed
