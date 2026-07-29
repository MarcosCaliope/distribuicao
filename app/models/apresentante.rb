class Apresentante < ApplicationRecord
  include Inativavel

  CONVENIOS = %w[C I B].freeze # CDA, Isento, Banco

  has_many :bancos
  has_many :titulos

  normalizes :codigo_legado, with: ->(codigo_legado) { codigo_legado.presence }

  validates :nome, presence: true
  validates :convenio, inclusion: { in: CONVENIOS }, allow_nil: true
  validates :codigo_legado, uniqueness: true, allow_nil: true
end
