class SessoesController < ApplicationController
  permitir_acesso_sem_autenticacao only: %i[ new create ]
  permitir_acesso_com_senha_a_trocar only: :destroy
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_sessao_url, alert: "Tente novamente mais tarde." }

  def new
  end

  def create
    if usuario = Usuario.ativos.authenticate_by(params.permit(:login, :password))
      iniciar_sessao_para usuario
      redirect_to url_apos_autenticacao
    else
      redirect_to new_sessao_path, alert: "Login ou senha inválidos."
    end
  end

  def destroy
    encerrar_sessao
    redirect_to new_sessao_path
  end
end
