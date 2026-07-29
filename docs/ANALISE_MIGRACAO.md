# Análise de Migração — Distribuidor (VB6 → Rails)

Fonte analisada: `D:\Fontes_SIAC_Andre\Projetos Smart\Distribuidor\fontes` (VB6, projeto `Distribuidor.vbp`).

## Resumo do sistema atual

Sistema em VB6 que importa uma remessa de títulos (protesto) em arquivo texto de layout
fixo (~600 bytes/linha), valida e distribui os títulos entre cartórios cadastrados por um
esquema de rodízio/sorteio, e gera manifestos de retorno para os apresentantes/bancos e para
os ofícios distribuidores.

O banco de dados **já é PostgreSQL** (`Central`, host `localhost`), acessado via ADO/OLE
DB (`PostgreSQL OLE DB Provider`). Não existem chaves estrangeiras no schema (só uma, isolada);
toda integridade é garantida em código VB6, com SQL concatenado manualmente (sem parametrização
— risco de SQL injection generalizado no sistema atual).

O `.vbp` referencia arquivos fora da própria pasta (`..\..\biblioteca\Classes\*.cls`,
`..\..\..\..\SIAC\Distribuicao\Fontes\frmDescricaoIrregularidade.frm`), ou seja, o Distribuidor
compartilha banco e código com sistemas irmãos: Testamentos (`tes_movimento`), Escrituras
Capital/Interior (`esc_capital`/`esc_interior`), e um sistema `SIAC` à parte.

## Fluxo de negócio (ponta a ponta)

1. **Correção manual (opcional)** — `frmCorrigeRemessa.frm`: patch de bytes conhecidos-ruins
   num arquivo bruto antes do import (ex.: força um campo do header, repadroniza CPF/CNPJ
   do sacador). Não toca banco, só reescreve o `.txt`.
2. **Importação** — `frmImpTitulos.frm` é quem de fato faz o parse do layout fixo (não é o
   `ModIMP.bas`, apesar do nome). Faz uma bateria de checagens de arquivo inteiro (arquivo já
   importado, caracteres inválidos, sequência de linhas, totais de header/trailer batendo,
   banco/apresentante cadastrado) antes de gravar. Depois, linha a linha: valida
   (`Criticas()`: dígito verificador de CPF/CNPJ, datas, nome devedor ≠ credor, endereço com
   número, etc.) — título inválido é **marcado como irregular, não descartado**. Grava em
   `cad_titulos` (linha principal) ou `tbldevedorsolidario` (codevedor), auto-cadastra devedor
   novo em `cad_devedor`, loga toda linha física em `tblremessas`. Arquivo importado é movido
   para `processados/`.
3. **Distribuição/rodízio** — `frmDistribuicaoNew.frm` + `ModIMP.bas`: para cada título sem
   cartório, determina a faixa de valor (`cad_faixas`), verifica vagas livres do dia naquela
   faixa em `tblDistribuicao` (reseta a faixa inteira quando esgota), sorteia um cartório entre
   os livres da faixa, e escolhe um ofício distribuidor (só existem 2) por rodízio simples
   separado. Reescreve `cad_titulos.protocolo` como
   `cartório + distribuidor + protocolo_original_zero_padded` — ou seja, **`protocolo` é um
   valor derivado e mutável**, não um ID estável.
4. **Exportação/manifestos** — `frmExportaTitulosDistribuicao.frm` gera um `.rem` por ofício
   distribuidor (manifesto interno, sem e-mail — puro arquivo local); `frmExportaTitulos.frm`
   gera um arquivo por cartório+apresentante no mesmo layout do import. O destinatário do
   e-mail é o **cartório** (`cad_protesto.pro_email`/`scopiaemail`), não o banco — "retorno ao
   banco" é impreciso, o assunto do e-mail legado é literalmente `"Arquivos da Distribuição,
   Ofício " & pro_id`. `tblarquivos` é só uma fila de registro em banco; o envio de fato é
   `cmdEmail_Click`, um botão manual que dispara `SendMail` (automação COM síncrona do
   Outlook, `ModIMP.bas`) — não existe job assíncrono nem processo agendado no legado. "Fila de
   e-mail" no legado significa "linha gravada em `tblarquivos` esperando alguém clicar
   Enviar", não uma fila de verdade.
5. **Relatórios** — 11 relatórios Crystal Reports, dirigidos por só 6 telas (`frmRelTitulos.frm`
   sozinho cobre 3 modos via botão de opção, reaproveitando o mesmo pipeline
   filtro→dataset→Viewer/Impressora/PDF).

## Schema real (extraído do dump `sc050126.backup`, autoritativo)

Tabelas centrais do domínio Distribuidor: `cad_titulos`, `tbldevedorsolidario`, `cad_devedor`,
`tblremessas`, `tbldistribuicao`, `cad_faixas`, `cad_protesto` (cartórios), `cad_distribuidor`
(ofícios distribuidores), `cad_bancos`, `cad_apresenta`, `cad_tipostit`, `cad_tipodoc`,
`tblferiados`, `tblarquivos`, sequência `seq_protocolo`.

Tabelas de sistemas irmãos que vivem no mesmo banco (não fazem parte do domínio Distribuidor,
mas podem colidir numa migração ingênua): `tes_movimento`/`tes_totaldia` (Testamentos),
`esc_capital`/`esc_interior` (Escrituras), `tblatos`, `smt_*`, `cax_*`, `cfg_*`, `ace_usuario`,
`cad_usuario`, `log_monitora`.

## Biblioteca compartilhada (`biblioteca/Classes/`)

- `BibCriticas.cls` — validações inline (campo vazio/número/data/zero), sem acumulador de erros.
- `BibGeral.cls` — leitura de INI/registro (credenciais de banco em texto puro), check-digit
  genérico.
- `BibUsuarios.cls` — permissões por sistema/programa/perfil (flags booleanas tipo "10101"),
  compara senha por igualdade de string.
- `BibSenhas.cls` — **cifra de substituição monoalfabética fixa, não é hash de verdade**
  (achado de segurança: tratar toda senha existente como comprometida).
- `BibCaracteres.cls` — `TrataDuplo`/`TrataMoeda` (normalização numérica), `Extenso` (valor por
  extenso em português), `UCaseInicial` (title-case com preposições minúsculas) — regras de
  negócio reais, portáveis.
- `BibFormularios.cls` — mecânica de UI do VB6, sem equivalente necessário no Rails.

## Bugs/inconsistências no VB6 (não replicar)

1. `ModIMP.DistribuirTituloUnico` calcula o sorteio por faixa mas **descarta o resultado** e
   usa só o rodízio simples — enquanto `frmDistribuicaoNew.cmdProcessar_Click` usa o sorteio
   por faixa de fato. Dois caminhos de distribuição com regras diferentes hoje. Resolvido: ver
   Etapa 3 abaixo — porta-se o comportamento de `cmdProcessar_Click` (tela principal).
2. `cmdDesfaz_Click` (desfazer distribuição) filtra por `txtDtRecebimento` em vez de
   `txtDtDistribuicao` — parece bug de digitação, já que o campo limpo é `dat_dist`.
3. `FormCheckCancelar` (trava "não cancela import já distribuído") tem o corpo comentado —
   trava morta hoje.
4. Testamentos/Escrituras: contador diário com copy-paste bug `ofi3 = ofi2 + 1`.
5. Várias validações em `FrmCadTitulos.FormCheck()` fazem `MsgBox` de aviso sem `Exit Function`
   — avisos que não bloqueiam o salvamento.
6. `tblParametros` recebe colunas adicionadas via `ALTER TABLE` disparado em runtime pelo
   próprio VB6 — levantar à parte quais colunas existem hoje em produção.
7. `frmDistribuicaoNew.cmdProcessar_Click` chama `ModIMP.BuscaCartorio(0)` a cada título, mas
   o cartório que essa função sorteia (primeiro `cad_protesto` com `blivre=true` em ordem de
   cursor, sem relação com faixa) **não é o cartório de fato gravado no título** — esse vem do
   sorteio por faixa em `tblDistribuicao` (`aTitDisp(iRandom)`). O único efeito de
   `BuscaCartorio` é marcar `cad_protesto.blivre=false` para um cartório não relacionado —
   código morto/vestigial (provavelmente sobra de um rodízio simples anterior ao sorteio por
   faixa). `cad_protesto.blivre` não reflete a distribuição real; não replicar essa flag como
   sinal de negócio. `ModIMP.BuscaDistribuidor(0)`, em contraste, é real: decide de fato o
   ofício distribuidor gravado no título (rodízio simples sobre `cad_distribuidor`, primeiro
   `blivre=true` com `dis_id<3` em ordem de cursor, reseta todos quando ambos ocupados).
8. `frmExportaTitulosDistribuicao.cmdImportar_Click` (o botão de exportar do manifesto por
   ofício — nome do evento é sobra de copy-paste, o caption é "&Exportar") aborta a exportação
   inteira (`MsgBox` + `Exit Sub`) se o **primeiro** ofício da data não tiver títulos, sem
   sequer tentar o segundo — comportamento assimétrico, não intencional. Não replicar: cada
   ofício deve ser pulado independentemente se não tiver títulos pendentes.
9. Mesmo form, nome do arquivo do manifesto (`"T1oficio" & Mid(Format(data,"ddmmyyyy"),1,4) &
   ".rem"`) usa só os 4 primeiros caracteres de `"ddmmyyyy"` — ou seja, **dia+mês, sem ano**.
   Exportações no mesmo dia-do-ano em anos diferentes sobrescrevem o arquivo uma da outra. Não
   se aplica ao Rails (Active Storage não depende de nome de arquivo pra não colidir), citado
   aqui só pra não ser confundido com um requisito do layout.
10. Mesmo form, `GeraDetalhe`: quando a busca por `cad_devedor` (endereço/CEP do devedor) não
    encontra nada, os dois campos são **omitidos inteiramente** da linha em vez de gravados em
    branco — desloca todos os bytes seguintes. Não replicar: todo campo de largura fixa tem que
    ser sempre escrito (em branco quando faltar dado), nunca omitido.
11. Mesmo form, `Format(rsTIT!dat_venc,"ddmmyyyy")` roda sem checar `IsNull` — `dat_venc` é
    nullable no schema; um título com vencimento em branco quebra a exportação no legado.
12. `frmExportaTitulos.frm`: nenhum dos dois exports (manifesto ou retorno) marca o título como
    "já exportado" — rodar de novo simplesmente sobrescreve o arquivo (`Open ... For Output`) e
    o upsert em `tblarquivos` (chave `pro_id+dist_id+data+cod_apr`). Tolerável quando é um
    humano clicando um botão; no Rails, como o envio de e-mail passa a ser um job automático
    (ver Etapa 4), a ausência de controle de duplicidade viraria reenvio duplicado em caso de
    retry — por isso a Etapa 4 introduz rastreamento novo (`titulo.manifesto_distribuidor_id`/
    `retorno_exportado_id`) que não existe no legado, decisão tomada com o usuário.
13. `frmRelArrecadacaoNew2.cmdImprimir_Click` (relatório "RelArrecadacao") executa `UPDATE
    cad_titulos SET sefeitofalencia='Y' WHERE ... AND dat_rece BETWEEN ...` como efeito colateral
    de simplesmente gerar o relatório — uma tela de relatório (leitura) mutando dado. Não
    replicar: o relatório correspondente na Etapa 5 é uma leitura pura, sem `UPDATE` nenhum.
14. **O sistema de login/permissões do legado é código morto.** `Sub Main` (`Appcode.bas`) tem
    a chamada de `frmSisLogin.Show` inteira comentada — o EXE compilado hoje não pede login
    nenhum, `frmmain.Show` acontece direto. `EXIGE_SENHA` continua declarada `True` mas não é
    lida em lugar nenhum (o bloco que a checava foi comentado junto). A conexão `gcnSupervisor`
    (onde ficam `tblUsuarios`/`tblPerfisCabeca`/`tblPerfisItens`/`tblProgramas`) também está
    comentada — mesmo que algo chamasse `UsuarioAutorizado`/`NivelAcesso`, quebraria na hora por
    falta de conexão. `ModIMP.ValidaAcesso` (o único wrapper que consultaria o flag de 5 bits
    "10101" — incluir/alterar/excluir/processar/cancelar — por perfil×programa) está definida
    mas não tem nenhum call site em nenhum form do Distribuidor. Ou seja: não existe hoje
    nenhuma authorização em tempo real de execução no Distribuidor — a Etapa 6 não porta
    comportamento legado nenhum aqui, constrói do zero.
15. A cifra de senha do legado (`BibSenhas.EncriptaSenha`) é uma substituição monoalfabética
    fixa sobre um alfabeto de 37 caracteres (`ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_` ↔
    `GMPA9NO70ZBCQ3X8_TRHYW6D5EKJFSUV2L1I4`), sem sal, sem KDF, trivialmente reversível com a
    mesma tabela — não é hash de verdade. Toda senha legada deve ser tratada como comprometida;
    nenhuma senha do legado é migrada sob nenhuma circunstância na Etapa 6.
16. `public.cad_usuario` (20 linhas, nomes reais, flag `usu_status` ativo/inativo) é a melhor
    candidata a tabela de usuários pra importar na Etapa 6, mas nenhum arquivo VB6 na árvore
    montada do legado lê ou escreve nela (grep exaustivo em toda a árvore Smart-suite, zero
    ocorrências) — não é possível confirmar que essa tabela pertence de fato ao Distribuidor.
    Decisão tomada com o usuário: importar mesmo assim (nome + login, nunca a senha), com troca
    de senha obrigatória pra todo usuário importado antes de fazer qualquer coisa.
17. `public.cad_titulos`/`public.cad_devedor` estão **vazios** (0 registros) na cópia restaurada
    — já confirmado com o usuário na Etapa 1 ("Achado de dados para a Etapa 7"): o legado purga
    títulos assim que são resolvidos, não existe tabela de histórico/arquivo separada. O único
    lugar onde dado histórico de título de fato existe é `public.tblremessas` (2.450.219 linhas,
    `datarem` 2022-01-12 a 2026-01-05) — guarda a linha bruta de largura fixa (`sregistro`,
    ~600 bytes) de cada registro de remessa já importado, no mesmo layout que
    `RemessaImportacao::Header`/`Detalhe`/`Trailer` já leem. `situacao`/`icodirreg` nessa tabela
    se correlacionam exatamente como a saída de `avaliar_criticas` do Rails
    (`situacao='5' ⟺ icodirreg≠0`, igual a como o Rails seta `tipo_ocorrencia: "5"` sempre que
    acha uma irregularidade) — são saída da própria lógica de crítica do legado gravada por
    linha, não dado independente. A Etapa 7 usa isso pra revalidar a lógica de crítica portada
    contra dado histórico real (ver item 18), não pra popular `titulos` — não haveria sentido em
    inserir milhões de títulos já resolvidos na tabela operacional viva.
18. Resolvida na Etapa 7 a ambiguidade que as Etapas 4 e 5 deixaram em aberto:
    `cad_protesto.ativa_sc_titulos` é a única flag de atividade que `cad_protesto` tem (não há
    coluna "ativo" separada) — o ETL mapeia `ativa_sc_titulos → Cartorio.ativo` diretamente, por
    ser o único sinal disponível.

## Plano por etapas

**Fase 0 — Decisões de escopo** (ver perguntas feitas ao usuário)
1. Escopo do MVP: só núcleo Distribuidor (import + rodízio + exportação), ou incluir
   Testamentos/Escrituras (mesmo código-base VB6, domínio diferente)?
2. Estratégia de schema: mapear tabelas legadas diretamente, ou modelar entidades novas e
   normalizadas + ETL a partir das legadas?
3. Convivência com o VB6: strangler fig (Rails novo aponta pro mesmo banco `Central`,
   corte tela por tela) vs corte único.
4. Autenticação: substituir `BibSenhas`/`BibUsuarios` por autenticação de verdade (reset de
   senha obrigatório) — assumido como certo, a menos que haja objeção. Resolvido na Etapa 6:
   gerador nativo de autenticação do Rails 8 (`bin/rails generate authentication`), não Devise
   — mais leve, código totalmente do próprio app, sem necessidade de OmniAuth/2FA hoje.

**Etapa 1 — Fundação (concluída)**: Rails 8.0.5 / Ruby 3.4.5 novo neste diretório.

Decisões confirmadas com o usuário:
- Escopo do MVP: só o núcleo Distribuidor (Testamentos/Escrituras ficam para depois).
- Banco de dev/teste: cópia local (para testes) do dump de produção
  `sc050126.backup`, restaurada no banco Postgres local `central`
  (owner `marcos`, superuser local).
- O Rails usa o **mesmo banco `central`** (sem banco separado) — mas as tabelas
  novas vivem num **schema Postgres dedicado `distribuidor`**, isoladas do
  schema `public` onde estão as ~40 tabelas legadas do VB6 (cad_*, tbl*, tes_*,
  esc_*, cax_*, cfg_*, smt_*, ace_usuario, log_monitora). Acesso ao legado a
  partir do Rails deve qualificar explicitamente `public.<tabela>`.
- **Achado técnico importante**: `schema_search_path` no `database.yml` isola
  onde as tabelas novas são *criadas*, mas **não** isola o que o dump do Rails
  (`db/schema.rb`, formato Ruby) *lista* — esse dumper varre o banco inteiro
  independente do search_path. A isolação real só funciona trocando o formato
  de dump para `structure.sql` (via `pg_dump`), com
  `config.active_record.schema_format = :sql` e
  `config.active_record.dump_schemas = "distribuidor"` em
  `config/application.rb`. Sem isso, `db/schema.rb` acabava incluindo as
  tabelas legadas inteiras (e quebrava o `db:schema:load` do banco de teste
  por causa de uma sequence legada com referência inconsistente no dump).
- Inflexões de português adicionadas em `config/initializers/inflections.rb`
  (`devedor→devedores`, `custa→custas`, `distribuidor→distribuidores`) — a
  pluralização padrão do Rails (regras de inglês) errava esses nomes.
- Entidade "ofício distribuidor" (`cad_distribuidor` no legado, só 2 registros)
  batizada de `OficioDistribuidor` no Rails para não colidir com o nome do
  próprio projeto/app ("Distribuidor").

Models criados (schema `distribuidor`, todos com validações e associações
básicas — sem lógica de negócio ainda, isso fica para as próximas etapas):
`Cartorio`, `OficioDistribuidor`, `Apresentante`, `Banco`, `Devedor`,
`TipoTitulo`, `FaixaCusta`, `Feriado`, `Irregularidade`, `Titulo`,
`DevedorSolidario`.

Em `Titulo`: `id` interno estável é a chave real; `protocolo_original`
(imutável, valor de `seq_protocolo` no legado) e
`numero_protocolo_distribuido` (derivado, calculado uma vez na distribuição)
ficam separados de propósito — no VB6 os dois são o mesmo campo mutado
in-place. Tabela `irregularidades` criada normalizada (schema pronto), mas
**as ~70 descrições ainda precisam ser extraídas de `FrmCadTitulos.labelIrreg()`
e semeadas** — não foram inventadas.

**Achado de dados para a Etapa 7 (ETL)**: na cópia restaurada, `cad_titulos`
está vazio (0 registros), enquanto `tblremessas` (log bruto de toda linha
importada) tem ~2,45 milhões de linhas, `cad_bancos` 4.831 e `cad_apresenta`
5.776. **Confirmado com o usuário**: é normal — `cad_titulos` em produção só
guarda títulos em aberto (não há tabela de histórico/arquivo à parte a
localizar). O ETL da Etapa 7 deve tratar `cad_titulos` como "só o que está
pendente hoje", não como histórico completo.

**Etapa 2 — Importação de remessa (concluída)**: parser do layout fixo (`app/services/remessa_importacao/`:
`Header`, `Detalhe`, `Trailer`, `Importador`, `ErroArquivo`) + validações de arquivo inteiro
(arquivo já importado, caracteres inválidos, sequência de linhas, banco/apresentante
cadastrado, totais e somatório de segurança do header/trailer) antes de gravar qualquer
título. Layout de bytes **validado campo a campo contra arquivos reais de produção**
(`D0010706.211` etc., copiados para `test/fixtures/files/remessas/`), incluindo o checksum
de segurança (15+15+14+1=45 bateu exatamente).

Achados corrigindo o relatório de exploração inicial:
- `Criticas()` (validações por título) está em `frmImpTitulos.frm`, não em `ModIMP.bas`.
- O valor do título vem do byte 247 (não 261 — esse é usado só no somatório de segurança
  do trailer, lido mas na prática não comparado a nada no código atual).
- O somatório de segurança do trailer só valida **quantidade**, não valor (o valor é lido
  do trailer mas nunca comparado).

Mapeamento exato de crítica → código de irregularidade extraído linha a linha de
`frmImpTitulos.frm` (não inventado): espécie não cadastrada→21, CPF/CNPJ do devedor
inválido→7, CPF/CNPJ do sacador/credor inválido→10, número do título vazio→16, endereço do
devedor insuficiente→6, data de emissão inválida→50, vencimento inválido/no futuro ou
emissão>vencimento→1, nome devedor igual a cedente/sacador→3, documento devedor zerado→50,
documento devedor igual ao do sacador→7, praça/cidade divergente (exceto apresentante
"073")→15, falência de CPF→50. Como no legado, **a última crítica que falha é a que vale**
(não é uma lista — só o último código sobrescreve os anteriores), comportamento replicado
de propósito para paridade.

As 70 descrições de irregularidade foram extraídas de `FrmCadTitulos.frm#labelIrreg` (não
inventadas) e semeadas em `db/seeds.rb`/`Irregularidade`.

Correções de schema descobertas ao implementar (Etapa 1 tinha ficado incompleta nestes
pontos):
- `titulos.tipo_titulo_id` e `titulos.protocolo_original` passaram a aceitar `NULL`
  (espécie não cadastrada não tem tipo real para associar; `protocolo_original` só serve
  para proveniência de dados do ETL, não para títulos novos).
- `devedores.tipo_documento` e `titulos.tipo_documento_devedor` alargados de 3 para 4
  caracteres (usamos "CNPJ" em vez do "CGC" arcaico do legado).

Divergências propositais em relação ao legado:
- Auditoria bruta linha-a-linha (`tblremessas`, 2,45M registros em produção) virou anexo
  de arquivo via Active Storage no model `Remessa`, em vez de uma tabela crescendo pra
  sempre.
- `Devedor.cpf_cnpj` preserva zeros à esquerda (o legado convertia para `Double` em alguns
  pontos — um bug de arredondamento que não foi replicado).
- "Cidade da empresa" (hardcoded `"FORTALEZA"` no VB6) virou config
  (`Rails.application.config.x.remessa.cidade_sede`, `ENV["REMESSA_CIDADE_SEDE"]`).
- Arquivo pós-import não é mais movido para pasta `processados/` no disco — o status fica
  no registro `Remessa` (`pendente`/`importada`/`com_erro`/`cancelada`) e o arquivo original
  fica anexado.

Testado com o arquivo real `D0010706.211` (15 títulos: 14 `DMI` regulares + 1 `DSI` marcado
irregular por espécie não cadastrada) — 17 testes automatizados em
`test/services/remessa_importacao/` (rubocop limpo).

**Etapa 3 — Distribuição/rodízio**: portar o comportamento de
`frmDistribuicaoNew.cmdProcessar_Click` (sorteio por faixa de valor via `cad_faixas`) — é a
tela principal usada pelos cartórios no dia a dia; confirmado com o usuário em 2026-07-28.
`ModIMP.DistribuirTituloUnico` (que calcula o sorteio por faixa e descarta o resultado, caindo
no rodízio simples) é caminho raramente usado e **não deve ser replicado** — tratar como o bug
que é, não como comportamento alternativo válido. Resolver a condição de corrida do
`UPDATE ... WHERE blivre=true` sem lock via transação + lock otimista/pessimista.

**Etapa 4 — Exportação/manifestos**: duas saídas independentes. (a) Manifesto por ofício
distribuidor — layout próprio de 302 bytes, só linhas de detalhe (sem header/trailer), sem
e-mail. (b) Retorno por cartório+apresentante — reaproveita byte a byte o layout do import
(`header.rb`/`detalhe.rb`/`trailer.rb`), mais um bloco de 42 bytes (posições 446-487) com dados
de ocorrência de protesto que o import não lê; como o app ainda não tem rastreamento de
ocorrência de protesto (`custas`, `data_ocorrencia`, declaração do portador não existem em
lugar nenhum), esses subcampos saem em branco por ora — lacuna conhecida, não uma omissão
silenciosa. O envio por e-mail (só do retorno, não do manifesto) via job assíncrono é
comportamento novo, não uma port: o legado nunca teve fila de verdade (ver item 12 acima).

**Etapa 5 — Relatórios**: consolidar os relatórios Crystal Reports numa única concern de
relatório Rails (HTML/PDF via Prawn). Correção ao parágrafo original desta etapa: são **8
telas, não 6** (`frmRelTitulos.frm`, `frmRelArrecadacaoNew2.frm`, `frmRelSMT.frm`,
`frmRelRankingDevedor.frm`, `frmCadApresentantes.frm` no domínio Distribuidor; `fmrCadTestamentos.frm`,
`frmCadEscrInterior.frm`, `frmCadEscrCapital.frm` nos domínios irmãos Testamentos/Escrituras) —
das quais só **4 telas / 7 modos de relatório** são de fato do domínio Distribuidor:
`frmRelTitulos.frm` (Eventuais, Por Apresentante com alternância Sintético, Por Devedor),
`frmRelArrecadacaoNew2.frm` (Arrecadação, Total de Títulos), `frmRelRankingDevedor.frm`
(Ranking) e `frmCadApresentantes.frm` (roster de apresentantes, 5 modos de ordenação/filtro).
`frmRelSMT.frm` consulta `smt_registro`/`smt_devedor`, tabelas que a própria seção "Schema real"
deste documento já lista como fora do domínio Distribuidor — tratado como fora de escopo, igual
aos 3 telas de Testamentos/Escrituras. O relatório de Arrecadação do legado mistura contagens de
títulos com Escrituras/Testamentos; como nenhum dos dois sistemas irmãos é modelado neste app
(fora do MVP, ver Fase 0), a versão Rails cobre só títulos — lacuna de escopo conhecida, não uma
omissão. O agrupamento exato do modo "Sintético" de Por Apresentante não pôde ser confirmado (o
`.rpt` é um binário Crystal Reports, ilegível) — a versão Rails assume agrupamento por cartório,
premissa a validar contra uso real, não fato confirmado.

**Etapa 6 — Autenticação/autorização**: gerador nativo do Rails 8 (`Usuario`/`Sessao`, não
Devise) + Pundit, com tabela `Perfil`/`Permissao` de verdade (muitos-para-muitos, não uma coluna
`role`). O sistema de login/permissões do legado é código morto (item 14 acima) — nada aqui é
port de comportamento legado, é construção nova. Usuários iniciais vêm de um import best-effort
de `public.cad_usuario` (item 16 acima), separado do `db:seed` automático (a tabela legada não
existe no Postgres limpo que o CI usa). Escopo por cartório fica de fora deliberadamente — sem
precedente no legado e sem tela de CRUD hoje que precise disso.

**Etapa 7 — Migração de dados + validação em paralelo**: duas partes independentes, confirmado
com o usuário (ver itens 17-18 acima). (a) ETL de dimensão/referência de verdade —
`Cartorio`/`OficioDistribuidor`/`Banco`/`Apresentante`/`TipoTitulo`/`FaixaCusta`/`Feriado`, hoje
vazios ou sem seed real — segue o mesmo padrão da Etapa 6
(`Autenticacao::ImportadorUsuariosLegado`): SQL cru contra `public.*`, serviço idempotente,
task rake fininha, fora de `db/seeds.rb`/CI. (b) Suite de validação — **não** um backfill de
títulos (não haveria "título pendente" legado pra migrar, `cad_titulos` está vazio): reconstrói
arquivos de remessa históricos a partir de `tblremessas.sregistro`, roda pelo
`RemessaImportacao::Importador` de verdade dentro de uma transação sempre desfeita
(`ActiveRecord::Rollback`), e compara a irregularidade/ocorrência computada contra
`icodirreg`/`situacao` gravados pelo legado pra aquela mesma linha — valida a lógica de crítica
portada contra dado histórico real em escala, sem gravar nada.

**Etapa 8 — Corte**: strangler fig tela por tela, desligando a tela equivalente no VB6
conforme cada parte entra em produção no Rails.
