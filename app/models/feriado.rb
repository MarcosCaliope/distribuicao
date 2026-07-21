class Feriado < ApplicationRecord
  validates :data, presence: true, uniqueness: true
  validates :descricao, presence: true
end
