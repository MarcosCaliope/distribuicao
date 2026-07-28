class Permissao < ApplicationRecord
  has_many :perfil_permissoes, dependent: :destroy
  has_many :perfis, through: :perfil_permissoes

  validates :chave, presence: true, uniqueness: true
end
