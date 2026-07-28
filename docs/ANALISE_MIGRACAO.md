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
   distribuidor (manifesto interno); `frmExportaTitulos.frm` gera um arquivo por
   cartório+apresentante no mesmo layout do import (retorno ao banco), enfileirado para e-mail
   via `tblarquivos`.
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

## Plano por etapas

**Fase 0 — Decisões de escopo** (ver perguntas feitas ao usuário)
1. Escopo do MVP: só núcleo Distribuidor (import + rodízio + exportação), ou incluir
   Testamentos/Escrituras (mesmo código-base VB6, domínio diferente)?
2. Estratégia de schema: mapear tabelas legadas diretamente, ou modelar entidades novas e
   normalizadas + ETL a partir das legadas?
3. Convivência com o VB6: strangler fig (Rails novo aponta pro mesmo banco `Central`,
   corte tela por tela) vs corte único.
4. Autenticação: substituir `BibSenhas`/`BibUsuarios` por Devise + bcrypt (reset de senha
   obrigatório) — assumido como certo, a menos que haja objeção.

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

**Etapa 4 — Exportação/manifestos**: manifesto por ofício distribuidor + retorno por
cartório/apresentante no layout fixo, fila de e-mail como job assíncrono.

**Etapa 5 — Relatórios**: consolidar os 11 relatórios Crystal Reports (dirigidos por só 6
telas) numa única concern de relatório Rails (HTML/PDF via Prawn ou WickedPDF).

**Etapa 6 — Autenticação/autorização**: Devise + bcrypt; permissões via Pundit/CanCanCan
com tabela `Role`/`Permission` de verdade.

**Etapa 7 — Migração de dados + validação em paralelo**: ETL das tabelas legadas, suite de
comparação campo a campo reimportando remessas históricas nos dois sistemas.

**Etapa 8 — Corte**: strangler fig tela por tela, desligando a tela equivalente no VB6
conforme cada parte entra em produção no Rails.
