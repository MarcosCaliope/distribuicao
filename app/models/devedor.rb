class Devedor < ApplicationRecord
  include Inativavel
  include Pesquisavel

  pesquisavel_por :nome, :cpf_cnpj

  has_many :titulos
  has_many :devedor_solidarios

  validates :tipo_documento, presence: true
  validates :cpf_cnpj, presence: true, uniqueness: { scope: :tipo_documento }
end
