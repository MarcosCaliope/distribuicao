module Cadastros
  class CartoriosController < ApplicationController
    before_action :set_cartorio, only: [ :edit, :update, :destroy ]

    def index
      @cartorios = Cartorio.order(:nome)
    end

    def new
      @cartorio = Cartorio.new
    end

    def create
      @cartorio = Cartorio.new(cartorio_params)
      if @cartorio.save
        redirect_to cadastros_cartorios_path, notice: "Cartório criado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @cartorio.update(cartorio_params)
        redirect_to cadastros_cartorios_path, notice: "Cartório atualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @cartorio.inativar!
      redirect_to cadastros_cartorios_path, notice: "Cartório inativado."
    end

    private

    def set_cartorio
      @cartorio = Cartorio.find(params[:id])
    end

    def cartorio_params
      params.require(:cartorio).permit(:codigo_legado, :nome, :oficial, :telefone, :email, :email_copia, :ativo)
    end
  end
end
