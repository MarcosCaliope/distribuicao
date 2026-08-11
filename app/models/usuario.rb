class Usuario < ApplicationRecord
  include Inativavel
  include Pesquisavel

  pesquisavel_por :nome, :login

  has_secure_password
  has_many :sessoes, dependent: :destroy

  has_many :perfil_usuarios, dependent: :destroy
  has_many :perfis, through: :perfil_usuarios

  validates :login, presence: true, uniqueness: true
  validates :nome, presence: true

  normalizes :login, with: ->(login) { login.strip.downcase }

  def tem_permissao?(chave)
    perfis.joins(:permissoes).where(permissoes: { chave: chave }).exists?
  end
end
