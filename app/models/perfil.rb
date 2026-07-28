class Perfil < ApplicationRecord
  has_many :perfil_usuarios, dependent: :destroy
  has_many :usuarios, through: :perfil_usuarios

  has_many :perfil_permissoes, dependent: :destroy
  has_many :permissoes, through: :perfil_permissoes

  validates :nome, presence: true, uniqueness: true
end
