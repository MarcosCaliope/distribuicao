module Cadastros
  class BancosController < ApplicationController
    before_action :set_banco, only: [ :edit, :update, :destroy ]
    before_action :carregar_apresentantes, only: [ :new, :create, :edit, :update ]

    def index
      @bancos = Banco.order(:nome)
    end

    def new
      @banco = Banco.new
    end

    def create
      @banco = Banco.new(banco_params)
      if @banco.save
        redirect_to cadastros_bancos_path, notice: "Banco criado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @banco.update(banco_params)
        redirect_to cadastros_bancos_path, notice: "Banco atualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @banco.inativar!
      redirect_to cadastros_bancos_path, notice: "Banco inativado."
    end

    private

    def set_banco
      @banco = Banco.find(params[:id])
    end

    def carregar_apresentantes
      @apresentantes = Apresentante.order(:nome)
    end

    def banco_params
      params.require(:banco).permit(
        :codigo_legado, :codigo_alfa, :nome, :apresentante_id, :valor_custa,
        :processa, :gera_remessa_cartorio, :sequencia_confirmacao, :email, :ativo
      )
    end
  end
end
