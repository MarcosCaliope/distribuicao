class ManifestoDistribuidor < ApplicationRecord
  belongs_to :oficio_distribuidor
  has_many :titulos

  has_one_attached :arquivo

  validates :data, presence: true
end
