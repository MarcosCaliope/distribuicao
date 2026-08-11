class TipoTitulo < ApplicationRecord
  include Inativavel
  include Pesquisavel

  pesquisavel_por :descricao, :codigo_legado, :abreviatura

  has_many :titulos

  normalizes :codigo_legado, with: ->(codigo_legado) { codigo_legado.presence }

  validates :descricao, presence: true
  validates :abreviatura, presence: true, uniqueness: true
  validates :codigo_legado, presence: true, uniqueness: true
end
