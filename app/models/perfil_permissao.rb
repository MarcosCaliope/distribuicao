class PerfilPermissao < ApplicationRecord
  belongs_to :perfil
  belongs_to :permissao

  validates :permissao_id, uniqueness: { scope: :perfil_id }
end
