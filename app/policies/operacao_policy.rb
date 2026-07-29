# frozen_string_literal: true

class OperacaoPolicy < ApplicationPolicy
  def executar?
    usuario.tem_permissao?("operar_distribuicao")
  end
end
