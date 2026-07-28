module Distribuicao
  # Sorteia um cartório livre para a faixa de custas do título, replicando o sorteio por
  # faixa de frmDistribuicaoNew.cmdProcessar_Click. Quando nenhuma vaga da faixa está livre,
  # a faixa inteira é resetada (todas ficam livres de novo) antes do sorteio — mesma regra
  # do legado. Bloqueia as vagas da faixa com FOR UPDATE para evitar a condição de corrida
  # do `UPDATE ... WHERE blivre=true` sem lock do legado (ver docs/ANALISE_MIGRACAO.md).
  class SorteioCartorio
    def self.reservar!(data:, faixa_custa:)
      ApplicationRecord.transaction do
        vagas = VagaDistribuicao
          .where(data: data, faixa_custa: faixa_custa)
          .lock("FOR UPDATE")
          .order(:id)
          .to_a

        if vagas.empty?
          raise ErroDistribuicao, "Nenhuma vaga de distribuição para a faixa " \
                                   "#{faixa_custa.tipo} em #{data}."
        end

        livres = vagas.select(&:livre)
        if livres.empty?
          VagaDistribuicao.where(id: vagas.map(&:id)).update_all(livre: true)
          livres = vagas
        end

        vaga = livres.sample
        vaga.update_columns(livre: false, quantidade_titulos: vaga.quantidade_titulos + 1)
        vaga.cartorio
      end
    end
  end
end
