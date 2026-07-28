# frozen_string_literal: true

class RelatorioPolicy < ApplicationPolicy
  def ver?
    usuario.tem_permissao?("ver_relatorios")
  end
end
