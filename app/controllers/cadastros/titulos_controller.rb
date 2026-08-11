module Cadastros
  # Cadastro manual de título — diferente das outras 5 tabelas deste namespace, Titulo não é
  # dimensão/referência: é a entidade transacional central, normalmente só criada via
  # RemessaImportacao::Importador. Esta tela fecha a lacuna descrita em
  # app/services/relatorios/titulos_eventuais.rb: títulos cadastrados manualmente (status "G",
  # o default da coluna) já eram um conceito no legado (frmCadTitulos.frm) e no relatório
  # "Eventuais", só não havia como criar um. Reaproveita a permissão gerenciar_cadastros (só
  # perfil administrador) por não haver hoje um motivo pra uma permissão nova, mesmo o dado
  # sendo diferente das outras 5 tabelas.
  class TitulosController < ApplicationController
    before_action :set_titulo, only: [ :edit, :update, :destroy ]
    before_action :carregar_listas, only: [ :new, :create, :edit, :update ]

    def index
      @titulos = Titulo.pesquisar(params[:q])
                        .includes(:cartorio, :devedor_solidarios)
                        .order(data_recebimento: :desc, id: :desc)
                        .limit(10)
    end

    def new
      @titulo = Titulo.new
    end

    def create
      @titulo = Titulo.new(titulo_params)
      @titulo.data_recebimento ||= Date.current
      @titulo.devedor = localizar_ou_criar_devedor || @titulo.devedor

      if @titulo.save
        redirect_to cadastros_titulos_path, notice: "Título criado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      @titulo.assign_attributes(titulo_params)
      @titulo.devedor = localizar_ou_criar_devedor || @titulo.devedor

      if @titulo.save
        redirect_to cadastros_titulos_path, notice: "Título atualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @titulo.data_distribuicao.present? || @titulo.devedor_solidarios.exists?
        redirect_to cadastros_titulos_path, alert: "Não é possível excluir um título já distribuído ou com devedor solidário."
        return
      end

      @titulo.destroy!
      redirect_to cadastros_titulos_path, notice: "Título excluído."
    end

    private

    def set_titulo
      @titulo = Titulo.find(params[:id])
    end

    def carregar_listas
      @tipo_titulos = TipoTitulo.ativos.order(:descricao)
      @apresentantes = Apresentante.ativos.order(:nome)
      @cartorios = Cartorio.ativos.order(:nome)
      @oficios_distribuidores = OficioDistribuidor.order(:nome)
      @irregularidades = Irregularidade.order(:codigo)
    end

    # Mesmo natural key (tipo_documento, cpf_cnpj) usado por
    # RemessaImportacao::Importador#localizar_ou_criar_devedor — cadastro manual não deve criar
    # um Devedor duplicado pra um documento que já existe. Sem os dois campos não dá pra
    # localizar nem criar; devolve nil e deixa as validações do próprio Titulo (presence de
    # tipo_documento_devedor/cpf_cnpj_devedor e a exigência do belongs_to :devedor) reportarem
    # o erro, em vez de estourar no find_or_create_by!.
    def localizar_ou_criar_devedor
      return nil if titulo_params[:tipo_documento_devedor].blank? || titulo_params[:cpf_cnpj_devedor].blank?

      Devedor.find_or_create_by!(
        tipo_documento: titulo_params[:tipo_documento_devedor],
        cpf_cnpj: titulo_params[:cpf_cnpj_devedor]
      ) do |devedor|
        devedor.nome = titulo_params[:nome_devedor]
        devedor.endereco = titulo_params[:endereco_devedor]
        devedor.cep = titulo_params[:cep_devedor]
        devedor.observacao = "inserido no cadastro manual de título"
      end
    end

    def titulo_params
      params.require(:titulo).permit(
        :tipo_documento_devedor, :cpf_cnpj_devedor, :nome_devedor, :endereco_devedor,
        :cep_devedor, :cidade_devedor, :uf_devedor,
        :tipo_titulo_id, :numero_titulo, :data_emissao, :data_vencimento, :data_recebimento,
        :valor, :cedente,
        :nome_sacador, :documento_sacador, :endereco_sacador, :cep_sacador, :cidade_sacador, :uf_sacador,
        :apresentante_id, :cartorio_id, :oficio_distribuidor_id, :irregularidade_id,
        :codigo_banco, :codigo_agencia, :efeito_falencia
      )
    end
  end
end
