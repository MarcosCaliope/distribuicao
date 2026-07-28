require "application_system_test_case"

class RelatoriosTest < ApplicationSystemTestCase
  test "filtra o relatório de títulos eventuais e vê o resultado na tela" do
    visit autenticado(relatorios_titulos_eventuais_path)

    assert_selector "h1", text: "Títulos Eventuais"

    fill_in "data_inicio", with: 5.days.ago.to_date
    fill_in "data_fim", with: Date.current
    click_on "Filtrar"

    assert_selector "h1", text: "Títulos Eventuais"
    assert_text "Nenhum registro encontrado"
  end

  private

  def autenticado(path)
    servidor = Capybara.current_session.server
    "http://#{ENV['RELATORIOS_USUARIO']}:#{ENV['RELATORIOS_SENHA']}@#{servidor.host}:#{servidor.port}#{path}"
  end
end
