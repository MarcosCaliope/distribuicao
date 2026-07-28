module Distribuicao
  # Garante que existem vagas de distribuição (cartório x faixa) para a data informada,
  # replicando frmDistribuicaoNew.CriaDistribuicao do legado: uma vaga por cartório ativo
  # x faixa de custas, com "livre" herdado do registro mais recente anterior para o mesmo
  # par (cartório, faixa) — ou false, se nunca houve um.
  class CriadorDia
    def initialize(data)
      @data = data
    end

    def criar!
      return if VagaDistribuicao.exists?(data: @data)

      ApplicationRecord.transaction do
        Cartorio.ativos.find_each do |cartorio|
          FaixaCusta.find_each do |faixa|
            VagaDistribuicao.create!(
              data: @data,
              cartorio: cartorio,
              faixa_custa: faixa,
              livre: livre_anterior?(cartorio, faixa)
            )
          end
        end
      end
    end

    private

    def livre_anterior?(cartorio, faixa)
      vaga_anterior = VagaDistribuicao
        .where(cartorio: cartorio, faixa_custa: faixa)
        .where("data < ?", @data)
        .order(data: :desc)
        .first

      vaga_anterior ? vaga_anterior.livre : false
    end
  end
end
