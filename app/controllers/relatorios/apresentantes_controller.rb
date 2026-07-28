module Relatorios
  class ApresentantesController < ApplicationController
    def index
      @dataset = Relatorios::ApresentantesRoster.new(modo: params[:modo]).gerar
      renderizar(@dataset)
    end
  end
end
