module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_usuario

    def connect
      set_current_usuario || reject_unauthorized_connection
    end

    private
      def set_current_usuario
        if sessao = Sessao.find_by(id: cookies.signed[:session_id])
          self.current_usuario = sessao.usuario
        end
      end
  end
end
