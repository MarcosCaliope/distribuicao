class FaixaCusta < ApplicationRecord
  validates :sequencial, presence: true, uniqueness: true
  validates :limite_inferior, :limite_superior, presence: true
end
