class Banco < ApplicationRecord
  belongs_to :apresentante, optional: true

  validates :codigo_legado, presence: true, uniqueness: true
  validates :nome, presence: true
end
