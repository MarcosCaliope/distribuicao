module Cadastros
  class FaixaCustasController < ApplicationController
    before_action :set_faixa_custa, only: [ :edit, :update, :destroy ]

    def index
      @faixa_custas = FaixaCusta.order(:sequencial)
    end

    def new
      @faixa_custa = FaixaCusta.new
    end

    def create
      @faixa_custa = FaixaCusta.new(faixa_custa_params)
      if @faixa_custa.save
        redirect_to cadastros_faixa_custas_path, notice: "Faixa de custa criada."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @faixa_custa.update(faixa_custa_params)
        redirect_to cadastros_faixa_custas_path, notice: "Faixa de custa atualizada."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @faixa_custa.inativar!
      redirect_to cadastros_faixa_custas_path, notice: "Faixa de custa inativada."
    end

    private

    def set_faixa_custa
      @faixa_custa = FaixaCusta.find(params[:id])
    end

    def faixa_custa_params
      params.require(:faixa_custa).permit(
        :sequencial, :tipo, :valor, :numero_cartorios, :quantidade_dia,
        :limite_inferior, :limite_superior, :ativo
      )
    end
  end
end
