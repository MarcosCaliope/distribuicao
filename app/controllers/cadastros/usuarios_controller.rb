module Cadastros
  # Senha nunca é digitada pelo administrador — sempre gerada aleatoriamente (create/
  # resetar_senha) e marcada deve_trocar_senha, mesmo padrão do
  # Autenticacao::ImportadorUsuariosLegado. É exibida uma única vez via flash, no redirect;
  # não fica gravada em nenhum lugar recuperável depois disso.
  class UsuariosController < ApplicationController
    before_action :set_usuario, only: [ :edit, :update, :destroy, :resetar_senha ]

    def index
      @usuarios = Usuario.order(:nome).includes(:perfis)
    end

    def new
      @usuario = Usuario.new
    end

    def create
      senha_temporaria = SecureRandom.alphanumeric(12)
      @usuario = Usuario.new(usuario_params)
      @usuario.password = senha_temporaria
      @usuario.deve_trocar_senha = true

      if @usuario.save
        redirect_to cadastros_usuarios_path,
          notice: "Usuário #{@usuario.login} criado. Senha temporária: #{senha_temporaria} (anote agora, não será exibida de novo)."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @usuario.update(usuario_params)
        redirect_to cadastros_usuarios_path, notice: "Usuário atualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @usuario.inativar!
      redirect_to cadastros_usuarios_path, notice: "Usuário inativado."
    end

    def resetar_senha
      senha_temporaria = SecureRandom.alphanumeric(12)
      @usuario.update!(password: senha_temporaria, deve_trocar_senha: true)
      redirect_to cadastros_usuarios_path,
        notice: "Senha de #{@usuario.login} redefinida: #{senha_temporaria} (anote agora, não será exibida de novo)."
    end

    private

    def set_usuario
      @usuario = Usuario.find(params[:id])
    end

    def usuario_params
      params.require(:usuario).permit(:login, :nome, :ativo, perfil_ids: [])
    end
  end
end
