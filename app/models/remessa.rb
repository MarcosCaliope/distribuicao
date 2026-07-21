class Remessa < ApplicationRecord
  STATUSES = %w[pendente importada com_erro cancelada].freeze

  belongs_to :banco, optional: true
  belongs_to :apresentante, optional: true
  has_many :titulos

  has_one_attached :arquivo

  validates :nome_arquivo, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
end
