module Distribuicao
  # Distribui os títulos pendentes de uma data entre cartórios e ofícios distribuidores,
  # replicando frmDistribuicaoNew.cmdProcessar_Click do legado (ver docs/ANALISE_MIGRACAO.md,
  # seção Etapa 3, e o item 7 do histórico de bugs para o que foi deliberadamente deixado
  # de fora). Cada título é distribuído na sua própria transação — um título sem faixa
  # correspondente é registrado como falha e não interrompe o restante do lote, na mesma
  # linha de "sinalizar em vez de rejeitar" já usada em RemessaImportacao.
  class Processador
    Falha = Struct.new(:titulo, :mensagem)

    def initialize(data: Date.current)
      @data = data
    end

    def processar
      CriadorDia.new(@data).criar!

      falhas = []
      Titulo.pendentes_distribuicao.find_each do |titulo|
        ApplicationRecord.transaction { distribuir!(titulo) }
      rescue ErroDistribuicao => e
        falhas << Falha.new(titulo, e.message)
      end
      falhas
    end

    private

    def distribuir!(titulo)
      faixa = FaixaCusta.find_by(
        "limite_inferior <= :valor AND limite_superior >= :valor", valor: titulo.valor
      )
      unless faixa
        raise ErroDistribuicao, "Nenhuma faixa de custas encontrada para o valor #{titulo.valor}."
      end

      cartorio = SorteioCartorio.reservar!(data: @data, faixa_custa: faixa)
      oficio = RodizioOficio.reservar!

      titulo.update!(
        cartorio: cartorio,
        oficio_distribuidor: oficio,
        data_distribuicao: @data,
        numero_protocolo_distribuido: protocolo(cartorio, oficio, titulo)
      )
    end

    # protocolo_original só existe para títulos importados via ETL do legado (ver Titulo);
    # títulos novos (o caso comum hoje) não o têm, então cai para o id — que cumpre o mesmo
    # papel de "número sequencial estável" que o legado tirava de seq_protocolo.
    def protocolo(cartorio, oficio, titulo)
      numero_base = (titulo.protocolo_original.presence || titulo.id).to_s.rjust(8, "0")
      "#{cartorio.codigo_legado}#{oficio.codigo_legado}#{numero_base}"
    end
  end
end
