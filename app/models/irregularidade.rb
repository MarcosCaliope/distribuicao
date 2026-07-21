class Irregularidade < ApplicationRecord
  has_many :titulos

  validates :codigo, presence: true, uniqueness: true
  validates :descricao, presence: true
end
