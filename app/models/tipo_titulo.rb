class TipoTitulo < ApplicationRecord
  include Inativavel

  has_many :titulos

  normalizes :codigo_legado, with: ->(codigo_legado) { codigo_legado.presence }

  validates :descricao, presence: true
  validates :abreviatura, presence: true, uniqueness: true
  validates :codigo_legado, presence: true, uniqueness: true
end
