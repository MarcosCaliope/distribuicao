class RetornoExportado < ApplicationRecord
  belongs_to :cartorio
  belongs_to :apresentante
  has_many :titulos

  has_one_attached :arquivo

  validates :data, presence: true
end
