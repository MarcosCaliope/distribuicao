namespace :etl do
  IMPORTADORES_DIMENSAO = {
    cartorios: "Etl::ImportadorCartorios",
    oficios_distribuidores: "Etl::ImportadorOficiosDistribuidores",
    bancos: "Etl::ImportadorBancos",
    apresentantes: "Etl::ImportadorApresentantes",
    tipos_titulo: "Etl::ImportadorTiposTitulo",
    faixas_custa: "Etl::ImportadorFaixasCusta",
    feriados: "Etl::ImportadorFeriados"
  }.freeze

  def relatar_resultado_etl(nome, resultado)
    puts "#{nome}: #{resultado.criados.size} criado(s), #{resultado.ignorados} já existia(m), " \
         "#{resultado.falhas.size} falha(s)."
    resultado.falhas.each { |chave, erro| puts "  falha em #{chave}: #{erro}" }
  end

  IMPORTADORES_DIMENSAO.each do |nome, nome_classe|
    desc "Importa #{nome} das tabelas legadas (ver #{nome_classe})"
    task nome => :environment do
      relatar_resultado_etl(nome, nome_classe.constantize.new.importar!)
    end
  end

  desc "Roda todos os importadores de dimensão/referência (cartórios, ofícios, bancos, apresentantes, tipos de título, faixas de custa, feriados)"
  task importar_dimensoes: :environment do
    IMPORTADORES_DIMENSAO.each { |nome, nome_classe| relatar_resultado_etl(nome, nome_classe.constantize.new.importar!) }
  end

  desc "Reconstrói remessas históricas de public.tblremessas e revalida a crítica portada " \
       "contra icodirreg/situacao do legado, sem gravar nada. Uso: " \
       "bin/rails \"etl:validar_replay_historico[2026-01-01,2026-01-05]\" (datas opcionais, " \
       "padrão: últimos 90 dias)"
  task :validar_replay_historico, [ :data_inicio, :data_fim ] => :environment do |_t, args|
    data_fim = args[:data_fim].presence ? Date.parse(args[:data_fim]) : Date.current
    data_inicio = args[:data_inicio].presence ? Date.parse(args[:data_inicio]) : data_fim - 90.days

    resultado = Etl::ValidadorReplayHistorico.new(data_inicio: data_inicio, data_fim: data_fim).validar!

    puts "Período: #{data_inicio} a #{data_fim}"
    puts "Arquivos processados: #{resultado.arquivos_processados}"
    puts "Arquivos com erro: #{resultado.arquivos_com_erro.size}"
    resultado.arquivos_com_erro.each { |nome, erro| puts "  #{nome}: #{erro}" }
    puts "Títulos comparados: #{resultado.titulos_comparados}"
    puts "Títulos batendo: #{resultado.titulos_batendo}"
    puts "Divergências (amostra de até #{Etl::ValidadorReplayHistorico::LIMITE_AMOSTRA_MISMATCH}):"
    resultado.mismatches.each do |mismatch|
      puts "  #{mismatch[:arquivo]} protocolo=#{mismatch[:protocolo]}: " \
           "esperado=#{mismatch[:irregularidade_esperada]} obtido=#{mismatch[:irregularidade_obtida]}"
    end
  end
end
