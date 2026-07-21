class Cartorio < ApplicationRecord
  has_many :titulos

  validates :nome, presence: true

  scope :ativos, -> { where(ativo: true) }
end
