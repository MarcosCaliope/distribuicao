require "test_helper"

module Autenticacao
  class ImportadorUsuariosLegadoTest < ActiveSupport::TestCase
    # public.cad_usuario é uma tabela do legado, fora do schema `distribuidor` que as migrations
    # deste app gerenciam — não existe no banco de teste (nem no CI, que roda contra um Postgres
    # em branco, ver .github/workflows/ci.yml) a menos que seja criada aqui.
    setup do
      ActiveRecord::Base.connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS public.cad_usuario (
          usu_id integer,
          usu_nome varchar(45),
          usu_login varchar(10),
          usu_senha varchar(10),
          usu_status char(1)
        )
      SQL
      ActiveRecord::Base.connection.execute("DELETE FROM public.cad_usuario")
    end

    teardown do
      ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS public.cad_usuario")
    end

    test "importa só usuários com status ativo, com senha aleatória e troca obrigatória" do
      inserir_legado(login: "ativo1", nome: "Fulano Ativo", status: "A")
      inserir_legado(login: "inativo1", nome: "Fulano Inativo", status: "D")

      resultado = ImportadorUsuariosLegado.new.importar!

      assert_equal [ "ativo1" ], resultado.criados
      assert_equal 0, resultado.ignorados
      assert_not Usuario.exists?(login: "inativo1")

      usuario = Usuario.find_by!(login: "ativo1")
      assert_equal "Fulano Ativo", usuario.nome
      assert usuario.deve_trocar_senha
      assert_includes usuario.perfis.pluck(:nome), "operador"
    end

    test "é idempotente — rodar de novo não duplica nem reseta quem já foi importado" do
      inserir_legado(login: "ativo2", nome: "Fulano", status: "A")
      ImportadorUsuariosLegado.new.importar!
      senha_digest_original = Usuario.find_by!(login: "ativo2").password_digest

      resultado = ImportadorUsuariosLegado.new.importar!

      assert_empty resultado.criados
      assert_equal 1, resultado.ignorados
      assert_equal 1, Usuario.where(login: "ativo2").count
      assert_equal senha_digest_original, Usuario.find_by!(login: "ativo2").password_digest
    end

    test "login é normalizado pra minúsculas, sem duplicar por causa de caixa" do
      inserir_legado(login: "MaiUsculo", nome: "Fulano", status: "A")

      ImportadorUsuariosLegado.new.importar!

      assert Usuario.exists?(login: "maiusculo")
    end

    private

    def inserir_legado(login:, nome:, status:)
      ActiveRecord::Base.connection.execute(<<~SQL)
        INSERT INTO public.cad_usuario (usu_nome, usu_login, usu_senha, usu_status)
        VALUES ('#{nome}', '#{login}', 'XPTO12345', '#{status}')
      SQL
    end
  end
end
