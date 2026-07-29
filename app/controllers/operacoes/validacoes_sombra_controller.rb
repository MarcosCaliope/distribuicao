module Operacoes
  class ValidacoesSombraController < ApplicationController
    def index
      @execucoes = ValidacaoSombraExecucao.order(data_inicio: :desc).limit(30)
    end
  end
end
