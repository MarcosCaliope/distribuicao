module Distribuicao
  # Rodízio simples do ofício distribuidor, independente do sorteio por faixa (replica
  # ModIMP.BuscaDistribuidor do legado — não o BuscaCartorio vestigial descrito no item 7
  # de docs/ANALISE_MIGRACAO.md). Com apenas 2 ofícios cadastrados, alterna estritamente
  # entre eles, resetando ambos para livre quando os dois já foram usados.
  class RodizioOficio
    def self.reservar!
      ApplicationRecord.transaction do
        oficios = OficioDistribuidor.lock("FOR UPDATE").order(:id).to_a
        raise ErroDistribuicao, "Nenhum ofício distribuidor cadastrado." if oficios.empty?

        livres = oficios.select(&:livre)
        if livres.empty?
          OficioDistribuidor.where(id: oficios.map(&:id)).update_all(livre: true)
          livres = oficios
        end

        oficio = livres.first
        oficio.update_columns(livre: false)
        oficio
      end
    end
  end
end
