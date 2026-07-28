namespace :usuarios do
  desc "Importa usuários ativos de public.cad_usuario (legado) — ver Autenticacao::ImportadorUsuariosLegado"
  task importar_legado: :environment do
    resultado = Autenticacao::ImportadorUsuariosLegado.new.importar!
    puts "#{resultado.criados.size} usuário(s) criado(s), #{resultado.ignorados} já existia(m)."
  end
end
