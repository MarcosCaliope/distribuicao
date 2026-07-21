class Titulo < ApplicationRecord
  belongs_to :devedor
  belongs_to :tipo_titulo, optional: true
  belongs_to :apresentante, optional: true
  belongs_to :cartorio, optional: true
  belongs_to :oficio_distribuidor, optional: true
  belongs_to :irregularidade, optional: true
  belongs_to :remessa, optional: true

  has_many :devedor_solidarios

  validates :protocolo_original, uniqueness: true, allow_nil: true
  validates :numero_protocolo_distribuido, uniqueness: true, allow_nil: true
  validates :tipo_documento_devedor, :cpf_cnpj_devedor, presence: true
  validates :numero_titulo, presence: true
  validates :data_recebimento, presence: true
  validates :valor, presence: true, numericality: { greater_than: 0 }

  scope :distribuidos, -> { where.not(data_distribuicao: nil) }
  scope :pendentes_distribuicao, -> { where(data_distribuicao: nil) }
  scope :irregulares, -> { where.not(irregularidade_id: nil) }
end
