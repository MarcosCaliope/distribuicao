# frozen_string_literal: true

class CadastroPolicy < ApplicationPolicy
  def gerenciar?
    usuario.tem_permissao?("gerenciar_cadastros")
  end
end
