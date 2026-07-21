class TipoTitulo < ApplicationRecord
  has_many :titulos

  validates :descricao, presence: true
  validates :abreviatura, presence: true, uniqueness: true
end
