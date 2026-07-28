module Autenticacao
  extend ActiveSupport::Concern

  included do
    before_action :exigir_autenticacao
    before_action :exigir_troca_de_senha
    helper_method :autenticado?
  end

  class_methods do
    def permitir_acesso_sem_autenticacao(**options)
      skip_before_action :exigir_autenticacao, **options
      skip_before_action :exigir_troca_de_senha, **options
    end

    def permitir_acesso_com_senha_a_trocar(**options)
      skip_before_action :exigir_troca_de_senha, **options
    end
  end

  private
    def autenticado?
      retomar_sessao
    end

    def exigir_autenticacao
      retomar_sessao || solicitar_autenticacao
    end

    # A troca de senha obrigatória (usuários importados do legado, ver
    # Autenticacao::ImportadorUsuariosLegado) é reforçada aqui, depois da autenticação — só
    # entra em vigor pra quem já tem sessão válida.
    def exigir_troca_de_senha
      return unless Current.usuario&.deve_trocar_senha

      redirect_to edit_senha_path
    end

    def retomar_sessao
      Current.sessao ||= buscar_sessao_por_cookie
    end

    def buscar_sessao_por_cookie
      Sessao.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def solicitar_autenticacao
      session[:return_to_after_authenticating] = request.url
      redirect_to new_sessao_path
    end

    # Não existe rota raiz nesse app ainda (nenhuma tela de "início" definida) — cai pro
    # primeiro relatório como destino padrão até isso existir.
    def url_apos_autenticacao
      session.delete(:return_to_after_authenticating) || relatorios_titulos_eventuais_path
    end

    def iniciar_sessao_para(usuario)
      usuario.sessoes.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |sessao|
        Current.sessao = sessao
        cookies.signed.permanent[:session_id] = { value: sessao.id, httponly: true, same_site: :lax }
      end
    end

    def encerrar_sessao
      Current.sessao.destroy
      cookies.delete(:session_id)
    end
end
