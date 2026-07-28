class VagaDistribuicao < ApplicationRecord
  belongs_to :cartorio
  belongs_to :faixa_custa

  validates :data, presence: true
end
