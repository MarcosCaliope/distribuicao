module Relatorios
  # Ponto de entrada dos relatórios — substitui o menu principal do legado (as 6 telas de
  # frmRel*/frmCadApresentantes eram acessadas por um menu, não por URL direta). Sem isso, a
  # única forma de chegar num relatório era conhecer a URL de cor (ver comentário histórico em
  # Autenticacao#url_apos_autenticacao) — necessário pra Fase 1 do corte (Etapa 8) ter uma tela
  # de verdade pro operador navegar, não só rotas que funcionam.
  class MenuController < ApplicationController
    def index
    end
  end
end
