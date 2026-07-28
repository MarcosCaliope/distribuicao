class ApplicationController < ActionController::Base
  include Autenticacao
  include Pundit::Authorization
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def pundit_user
    Current.usuario
  end
end
