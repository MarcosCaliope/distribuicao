module Distribuicao
  # Desfaz a distribuição dos títulos de uma data, replicando frmDistribuicaoNew.cmdDesfaz_Click
  # do legado — mas filtrando por data_distribuicao, corrigindo o bug de digitação do legado
  # (que filtrava por txtDtRecebimento; ver item 2 de docs/ANALISE_MIGRACAO.md). Assim como o
  # legado, não devolve as vagas de distribuição nem os ofícios distribuidores ao estado
  # "livre" — desfazer afeta só o título, não o rodízio do dia.
  class Desfazedor
    def initialize(data)
      @data = data
    end

    def desfazer!
      Titulo.where(data_distribuicao: @data).update_all(
        cartorio_id: nil,
        oficio_distribuidor_id: nil,
        data_distribuicao: nil,
        numero_protocolo_distribuido: nil
      )
    end
  end
end
