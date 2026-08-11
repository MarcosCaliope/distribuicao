class Cartorio < ApplicationRecord
  include Inativavel
  include Pesquisavel

  pesquisavel_por :nome, :codigo_legado

  has_many :titulos

  normalizes :codigo_legado, with: ->(codigo_legado) { codigo_legado.presence }

  validates :nome, presence: true
  validates :codigo_legado, uniqueness: true, allow_nil: true
end
