class ValidacaoSombraExecucao < ApplicationRecord
  validates :data_inicio, :data_fim, presence: true

  def divergencias
    titulos_comparados - titulos_batendo
  end
end
