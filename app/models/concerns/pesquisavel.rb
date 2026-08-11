module Pesquisavel
  extend ActiveSupport::Concern

  class_methods do
    def pesquisavel_por(*campos)
      define_singleton_method(:pesquisar) do |termo|
        return all if termo.blank?

        condicoes = campos.map { |campo| "#{campo}::text ILIKE :termo" }.join(" OR ")
        where(condicoes, termo: "%#{sanitize_sql_like(termo)}%")
      end
    end
  end
end
