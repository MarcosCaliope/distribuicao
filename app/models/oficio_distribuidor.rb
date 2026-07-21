class OficioDistribuidor < ApplicationRecord
  has_many :titulos

  validates :nome, presence: true
end
