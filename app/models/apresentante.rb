class Apresentante < ApplicationRecord
  CONVENIOS = %w[C I B].freeze # CDA, Isento, Banco

  has_many :bancos
  has_many :titulos

  validates :nome, presence: true
  validates :convenio, inclusion: { in: CONVENIOS }, allow_nil: true
end
