class Banco < ApplicationRecord
  include Inativavel
  include Pesquisavel

  pesquisavel_por :nome, :codigo_legado, :codigo_alfa

  belongs_to :apresentante, optional: true

  normalizes :codigo_alfa, with: ->(codigo_alfa) { codigo_alfa.presence }

  validates :codigo_legado, presence: true, uniqueness: true
  validates :codigo_alfa, uniqueness: true, allow_nil: true
  validates :nome, presence: true
end
