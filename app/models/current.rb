class Current < ActiveSupport::CurrentAttributes
  attribute :sessao
  delegate :usuario, to: :sessao, allow_nil: true
end
