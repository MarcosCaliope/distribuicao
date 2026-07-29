class FaixaCusta < ApplicationRecord
  include Inativavel

  validates :sequencial, presence: true, uniqueness: true
  validates :tipo, presence: true
  validates :limite_inferior, :limite_superior, presence: true
end
