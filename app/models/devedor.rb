class Devedor < ApplicationRecord
  has_many :titulos
  has_many :devedor_solidarios

  validates :tipo_documento, presence: true
  validates :cpf_cnpj, presence: true, uniqueness: { scope: :tipo_documento }
end
