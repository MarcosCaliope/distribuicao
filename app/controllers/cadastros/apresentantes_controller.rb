module Cadastros
  class ApresentantesController < ApplicationController
    before_action :set_apresentante, only: [ :edit, :update, :destroy ]

    def index
      @apresentantes = Apresentante.order(:nome)
    end

    def new
      @apresentante = Apresentante.new
    end

    def create
      @apresentante = Apresentante.new(apresentante_params)
      if @apresentante.save
        redirect_to cadastros_apresentantes_path, notice: "Apresentante criado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @apresentante.update(apresentante_params)
        redirect_to cadastros_apresentantes_path, notice: "Apresentante atualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @apresentante.inativar!
      redirect_to cadastros_apresentantes_path, notice: "Apresentante inativado."
    end

    private

    def set_apresentante
      @apresentante = Apresentante.find(params[:id])
    end

    def apresentante_params
      params.require(:apresentante).permit(
        :codigo_legado, :nome, :endereco, :telefone, :contato, :agencia,
        :tipo, :convenio, :custa_antecipada, :ativo
      )
    end
  end
end
