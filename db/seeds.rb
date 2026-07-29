# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Códigos de irregularidade — extraídos de FrmCadTitulos.frm#labelIrreg (VB6),
# não inventados. Descrições e numeração idênticas ao legado para manter
# paridade nos relatórios durante a migração.
IRREGULARIDADES = {
  1 => "Data da apresentação inferior à data de vencimento.",
  2 => "Falta de comprovante da prestação de serviço.",
  3 => "Nome do sacado incompleto/incorreto.",
  4 => "Nome do cedente incompleto/incorreto.",
  5 => "Nome do sacador incompleto/incorreto.",
  6 => "Endereço do sacado insuficiente.",
  7 => "CNPJ/CPF do sacado inválido/incorreto.",
  8 => "CNPJ/CPF incompatível c/ o nome do sacado/sacador/avalista",
  9 => "CNPJ/CPF do sacado incompatível com o tipo de documento.",
  10 => "CNPJ/CPF do sacador incompatível com a espécie.",
  11 => "Título aceito sem a assinatura do sacado.",
  12 => "Título aceito rasurado ou rasgado.",
  13 => "Título aceito falta título (ag ced: enviar).",
  14 => "CEP incorreto.",
  15 => "Praça de pagamento incompatível com endereço.",
  16 => "Falta número do título.",
  17 => "Título sem endosso do cedente ou irregular.",
  18 => "Falta data de emissão do título.",
  19 => "Título aceito: valor por extenso diferente do valor por numérico.",
  20 => "Data de emissão posterior ao vencimento.",
  21 => "Espécie inválida para protesto.",
  22 => "CEP do sacado incompatível com a praça de protesto.",
  23 => "Falta espécie do título.",
  24 => "Saldo maior que o valor do título.",
  25 => "Tipo de endosso inválido.",
  26 => "Devolvido por ordem judicial",
  27 => "Dados do título não conferem com disquete",
  28 => "Sacado e Sacador/Avalista são a mesma pessoa",
  29 => "Corrigir a espécie do título",
  30 => "Aguardar um dia útil após o vencimento para protestar",
  31 => "Data do vencimento rasurada",
  32 => "Vencimento extenso não confere com número",
  33 => "Falta data de vencimento no título",
  34 => "DM/DMI sem comprovante autenticado ou declaração",
  35 => "Comprovante ilegível para conferência e microfilmagem",
  36 => "Nome solicitado não confere com emitente ou sacado",
  37 => "Confirmar se são 2 emitentes. Se sim, indicar os dados dos 2",
  38 => "Endereço do sacado igual ao do sacador ou do portador",
  39 => "Endereço do apresentante incompleto ou não informado",
  40 => "Rua / Número inexistente no endereço",
  41 => "Informar a qualidade do endosso (M ou T)",
  42 => "Falta endosso do favorecido para o apresentante",
  43 => "Data da emissão rasurada",
  44 => "Protesto de cheque proibido motivo 20/25/28/30 ou 35",
  45 => "Falta assinatura do emitente no cheque",
  46 => "Endereço do emitente no cheque igual ao do banco sacado",
  47 => "Falta o motivo da devolução no cheque ou motivo ilegível",
  48 => "Falta assinatura do sacador no título",
  49 => "Nome do apresentante não informado/incompleto/incorreto",
  50 => "Erro de preenchimento do título",
  51 => "Título com direito de regresso vencido",
  52 => "Título apresentado em duplicidade",
  53 => "Título já protestado",
  54 => "Letra de Câmbio vencida falta aceite do sacado",
  55 => "Título falta tradução por tradutor público",
  56 => "Falta declaração de saldo assinada no título",
  57 => "Contrato de Câmbio falta conta gráfica",
  58 => "Ausência do Documento Físico",
  59 => "Sacado Falecido.",
  60 => "Sacado Apresentou Quitação do Título",
  61 => "Título de outra jurisdição territorial",
  # Texto truncado no próprio VB6 (FrmCadTitulos.frm) — preservado como está.
  62 => "Título com emissão anterior à concordata do sa",
  63 => "Sacado consta na lista de falência",
  64 => "Apresentante não aceita publicação de edital",
  65 => "Dados do sacador em branco ou inválido",
  66 => "Título sem autorização para protesto por edital",
  67 => "Valor divergente entre título e comprovante",
  68 => "Condomínio não pode ser protestado para fins falimentares",
  69 => "Vedada a intimação por edital para protesto falimentares",
  70 => "Dados do Cedente em branco ou inválido"
}.freeze

IRREGULARIDADES.each do |codigo, descricao|
  Irregularidade.find_or_create_by!(codigo: codigo) { |i| i.descricao = descricao }
end

# Permissões e perfis (Etapa 6/8). "administrador" acumula tudo que "operador" tem mais
# gerenciar_cadastros (CRUD das tabelas de dimensão) — primeira vez que os dois perfis se
# diferenciam de fato.
PERMISSOES = %w[ver_relatorios operar_distribuicao gerenciar_cadastros].freeze

PERFIS_PERMISSOES = {
  "operador" => %w[ver_relatorios operar_distribuicao],
  "administrador" => %w[ver_relatorios operar_distribuicao gerenciar_cadastros]
}.freeze

permissoes_por_chave = PERMISSOES.index_with { |chave| Permissao.find_or_create_by!(chave: chave) }
PERFIS_PERMISSOES.each do |nome, chaves|
  perfil = Perfil.find_or_create_by!(nome: nome)
  perfil.permissoes = chaves.map { |chave| permissoes_por_chave.fetch(chave) }
end
