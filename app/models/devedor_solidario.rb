class DevedorSolidario < ApplicationRecord
  belongs_to :titulo
  belongs_to :devedor

  validates :devedor_id, uniqueness: { scope: :titulo_id }
end
