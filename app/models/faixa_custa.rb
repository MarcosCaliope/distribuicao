class FaixaCusta < ApplicationRecord
  include Inativavel
  include Pesquisavel

  pesquisavel_por :sequencial, :tipo

  validates :sequencial, presence: true, uniqueness: true
  validates :tipo, presence: true
  validates :limite_inferior, :limite_superior, presence: true
end
