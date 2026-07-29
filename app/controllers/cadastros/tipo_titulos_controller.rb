module Cadastros
  class TipoTitulosController < ApplicationController
    before_action :set_tipo_titulo, only: [ :edit, :update, :destroy ]

    def index
      @tipo_titulos = TipoTitulo.order(:descricao)
    end

    def new
      @tipo_titulo = TipoTitulo.new
    end

    def create
      @tipo_titulo = TipoTitulo.new(tipo_titulo_params)
      if @tipo_titulo.save
        redirect_to cadastros_tipo_titulos_path, notice: "Tipo de título criado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @tipo_titulo.update(tipo_titulo_params)
        redirect_to cadastros_tipo_titulos_path, notice: "Tipo de título atualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @tipo_titulo.inativar!
      redirect_to cadastros_tipo_titulos_path, notice: "Tipo de título inativado."
    end

    private

    def set_tipo_titulo
      @tipo_titulo = TipoTitulo.find(params[:id])
    end

    def tipo_titulo_params
      params.require(:tipo_titulo).permit(:codigo_legado, :descricao, :abreviatura, :ativo)
    end
  end
end
