module Etl
  # Fase 3 da Etapa 8 (ver docs/ANALISE_MIGRACAO.md): roda Etl::ValidadorReplayHistorico
  # diariamente durante a janela de transição, comparando o dia anterior (já fechado) contra o
  # que o VB6 gravou, e persiste o resultado em ValidacaoSombraExecucao — sem isso, ninguém
  # ficaria acompanhando log de job por semanas. Agendado em config/recurring.yml. Não altera
  # ValidadorReplayHistorico (que continua servindo a task rake manual pra análise histórica
  # ad-hoc) — só empacota o mesmo resultado pra ficar visível.
  class ValidacaoSombraJob < ApplicationJob
    queue_as :default

    def perform(data: Date.yesterday)
      resultado = ValidadorReplayHistorico.new(data_inicio: data, data_fim: data).validar!

      ValidacaoSombraExecucao.create!(
        data_inicio: data,
        data_fim: data,
        arquivos_processados: resultado.arquivos_processados,
        titulos_comparados: resultado.titulos_comparados,
        titulos_batendo: resultado.titulos_batendo,
        arquivos_com_erro: resultado.arquivos_com_erro.map { |nome, erro| { arquivo: nome, erro: erro } },
        mismatches: resultado.mismatches
      )
    end
  end
end
