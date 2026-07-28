# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, "\\1en"
#   inflect.singular /^(ox)en/i, "\\1"
#   inflect.irregular "person", "people"
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym "RESTful"
# end

# Domínio em português (sistema Distribuidor): a pluralização padrão do
# Rails segue regras do inglês e erra nomes como "devedor"/"custa".
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular "devedor", "devedores"
  inflect.irregular "custa", "custas"
  inflect.irregular "distribuidor", "distribuidores"
  inflect.irregular "distribuicao", "distribuicoes"
  inflect.irregular "perfil", "perfis"
  inflect.irregular "permissao", "permissoes"
  inflect.irregular "sessao", "sessoes"
end
