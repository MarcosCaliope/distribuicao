require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Distribuicao
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # As tabelas do Rails vivem no schema Postgres "distribuidor", num banco
    # compartilhado com o schema "public" legado do VB6 (ver database.yml).
    # schema.rb (Ruby) não filtra por schema ao gerar o dump — captura o
    # banco inteiro. structure.sql via pg_dump com --schema aceita filtrar
    # de verdade, então usamos esse formato aqui.
    config.active_record.schema_format = :sql
    config.active_record.dump_schemas = "distribuidor"

    # No VB6 a "praça de pagamento"/"cidade do devedor" era comparada contra
    # "FORTALEZA" hardcoded (ver frmImpTitulos.frm) — parametrizado aqui para
    # não travar o código à comarca de um único cliente.
    config.x.remessa.cidade_sede = ENV.fetch("REMESSA_CIDADE_SEDE", "FORTALEZA")
  end
end
