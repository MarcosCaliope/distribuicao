# Troca de senha autenticada (não é fluxo de "esqueci minha senha" por e-mail — o app não tem
# SMTP configurado ainda, e usuários importados do legado não têm e-mail confirmado no
# cadastro; ver Autenticacao::ImportadorUsuariosLegado). Usada tanto pra troca obrigatória
# (usuário importado, deve_trocar_senha: true) quanto pra troca voluntária.
class SenhasController < ApplicationController
  permitir_acesso_com_senha_a_trocar

  def edit
  end

  def update
    if !Current.usuario.authenticate(params[:senha_atual])
      redirect_to edit_senha_path, alert: "Senha atual incorreta."
    elsif params[:nova_senha] != params[:nova_senha_confirmacao]
      redirect_to edit_senha_path, alert: "A confirmação não confere com a nova senha."
    elsif Current.usuario.update(password: params[:nova_senha], deve_trocar_senha: false)
      redirect_to url_apos_autenticacao, notice: "Senha alterada com sucesso."
    else
      redirect_to edit_senha_path, alert: Current.usuario.errors.full_messages.to_sentence
    end
  end
end
