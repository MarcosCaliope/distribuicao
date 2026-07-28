module Autenticacao
  # Importa usuários de `public.cad_usuario` (legado) — ver docs/ANALISE_MIGRACAO.md, item 16:
  # não foi possível confirmar de que sistema essa tabela é (nenhum fonte VB6 encontrado a
  # referencia), mas ficou decidido com o usuário importar mesmo assim. Nunca traz a senha do
  # legado (item 15 — cifra reversível, tratada como comprometida): toda conta importada recebe
  # uma senha aleatória nova e é marcada pra trocar no primeiro login. Idempotente — rodar de
  # novo não duplica nem reseta quem já foi importado.
  #
  # Deliberadamente fora de db/seeds.rb: o CI roda contra um Postgres em branco, sem schema
  # `public` nenhum do legado (ver .github/workflows/ci.yml) — colocar isso no seed automático
  # quebraria o CI. Só roda via `bin/rails usuarios:importar_legado`, manualmente, contra uma
  # cópia de verdade do banco "central".
  class ImportadorUsuariosLegado
    Resultado = Struct.new(:criados, :ignorados, keyword_init: true)

    def importar!
      perfil_operador = Perfil.find_by!(nome: "operador")
      criados = []
      ignorados = 0

      linhas_legado.each do |linha|
        login = linha["usu_login"].to_s.strip.downcase
        next if login.blank?

        if Usuario.exists?(login: login)
          ignorados += 1
          next
        end

        senha_temporaria = SecureRandom.alphanumeric(12)
        usuario = Usuario.create!(
          login: login,
          nome: linha["usu_nome"].to_s.strip.presence || login,
          password: senha_temporaria,
          deve_trocar_senha: true
        )
        usuario.perfis = [ perfil_operador ]
        criados << [ login, senha_temporaria ]
      end

      criados.each { |login, senha| puts "#{login}\t#{senha}" }
      Resultado.new(criados: criados.map(&:first), ignorados: ignorados)
    end

    private

    def linhas_legado
      ActiveRecord::Base.connection.select_all(
        "SELECT usu_login, usu_nome FROM public.cad_usuario WHERE usu_status = 'A'"
      )
    end
  end
end
