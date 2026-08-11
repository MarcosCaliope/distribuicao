module Cadastros
  class DevedoresController < ApplicationController
    before_action :set_devedor, only: [ :edit, :update, :destroy ]

    def index
      @devedores = Devedor.pesquisar(params[:q]).order(:nome)
    end

    def new
      @devedor = Devedor.new
    end

    def create
      @devedor = Devedor.new(devedor_params)
      if @devedor.save
        redirect_to cadastros_devedores_path, notice: "Devedor criado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @devedor.update(devedor_params)
        redirect_to cadastros_devedores_path, notice: "Devedor atualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @devedor.inativar!
      redirect_to cadastros_devedores_path, notice: "Devedor inativado."
    end

    private

    def set_devedor
      @devedor = Devedor.find(params[:id])
    end

    def devedor_params
      params.require(:devedor).permit(
        :tipo_documento, :cpf_cnpj, :nome, :endereco, :bairro, :cep,
        :observacao, :quantidade_titulos_pendentes, :ativo
      )
    end
  end
end
