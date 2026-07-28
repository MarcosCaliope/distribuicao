class PerfilUsuario < ApplicationRecord
  belongs_to :usuario
  belongs_to :perfil

  validates :perfil_id, uniqueness: { scope: :usuario_id }
end
