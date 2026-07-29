module Inativavel
  extend ActiveSupport::Concern

  included do
    scope :ativos, -> { where(ativo: true) }
  end

  def inativar!
    update!(ativo: false)
  end
end
