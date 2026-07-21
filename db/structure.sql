SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: distribuidor; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA distribuidor;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: distribuidor; Owner: -
--

CREATE TABLE distribuidor.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: distribuidor; Owner: -
--

CREATE SEQUENCE distribuidor.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: distribuidor; Owner: -
--

ALTER SEQUENCE distribuidor.active_storage_attachments_id_seq OWNED BY distribuidor.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: distribuidor; Owner: -
--

CREATE TABLE distribuidor.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: distribuidor; Owner: -
--

CREATE SEQUENCE distribuidor.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: distribuidor; Owner: -
--

ALTER SEQUENCE distribuidor.active_storage_blobs_id_seq OWNED BY distribuidor.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: distribuidor; Owner: -
--

CREATE TABLE distribuidor.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: distribuidor; Owner: -
--

CREATE SEQUENCE distribuidor.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: distribuidor; Owner: -
--

ALTER SEQUENCE distribuidor.active_storage_variant_records_id_seq OWNED BY distribuidor.active_storage_variant_records.id;


--
-- Name: apresentantes; Type: TABLE; Schema: distribuidor; Owner: -
--

CREATE TABLE distribuidor.apresentantes (
    id bigint NOT NULL,
    codigo_legado character varying(6),
    nome character varying NOT NULL,
    endereco character varying,
    telefone character varying,
    contato character varying,
    agencia character varying,
    tipo character varying(1),
    convenio character varying(1),
    custa_antecipada boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: apresentantes_id_seq; Type: SEQUENCE; Schema: distribuidor; Owner: -
--

CREATE SEQUENCE distribuidor.apresentantes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: apresentantes_id_seq; Type: SEQUENCE OWNED BY; Schema: distribuidor; Owner: -
--

ALTER SEQUENCE distribuidor.apresentantes_id_seq OWNED BY distribuidor.apresentantes.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: distribuidor; Owner: -
--

CREATE TABLE distribuidor.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: bancos; Type: TABLE; Schema: distribuidor; Owner: -
--

CREATE TABLE distribuidor.bancos (
    id bigint NOT NULL,
    codigo_legado character varying(6) NOT NULL,
    codigo_alfa character varying(6),
    nome character varying NOT NULL,
    apresentante_id bigint,
    valor_custa numeric(12,2),
    processa boolean DEFAULT true NOT NULL,
    gera_remessa_cartorio boolean DEFAULT true NOT NULL,
    sequencia_confirmacao integer,
    email character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: bancos_id_seq; Type: SEQUENCE; Schema: distribuidor; Owner: -
--

CREATE SEQUENCE distribuidor.bancos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bancos_id_seq; Type: SEQUENCE OWNED BY; Schema: distribuidor; Owner: -
--

ALTER SEQUENCE distribuidor.bancos_id_seq OWNED BY distribuidor.bancos.id;


--
-- Name: cartorios; Type: TABLE; Schema: distribuidor; Owner: -
--

CREATE TABLE distribuidor.cartorios (
    id bigint NOT NULL,
    codigo_legado character varying(6),
    nome character varying NOT NULL,
    oficial character varying,
    telefone character varying,
    email character varying,
    email_copia character varying,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: cartorios_id_seq; Type: SEQUENCE; Schema: distribuidor; Owner: -
--

CREATE SEQUENCE distribuidor.cartorios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cartorios_id_seq; Type: SEQUENCE OWNED BY; Schema: distribuidor; Owner: -
--

ALTER SEQUENCE distribuidor.cartorios_id_seq OWNED BY distribuidor.cartorios.id;


--
-- Name: devedor_solidarios; Type: TABLE; Schema: distribuidor; Owner: -
--

CREATE TABLE distribuidor.devedor_solidarios (
    id bigint NOT NULL,
    titulo_id bigint NOT NULL,
    devedor_id bigint NOT NULL,
    nosso_numero character varying,
    especie character varying(3),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: devedor_solidarios_id_seq; Type: SEQUENCE; Schema: distribuidor; Owner: -
--

CREATE SEQUENCE distribuidor.devedor_solidarios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: devedor_solidarios_id_seq; Type: SEQUENCE OWNED BY; Schema: distribuidor; Owner: -
--

ALTER SEQUENCE distribuidor.devedor_solidarios_id_seq OWNED BY distribuidor.devedor_solidarios.id;


--
-- Name: devedores; Type: TABLE; Schema: distribuidor; Owner: -
--

CREATE TABLE distribuidor.devedores (
    id bigint NOT NULL,
    tipo_documento character varying(4) NOT NULL,
    cpf_cnpj character varying(14) NOT NULL,
    nome character varying,
    endereco character varying,
    bairro character varying,
    cep character varying,
    observacao character varying,
    quantidade_titulos_pendentes integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: devedores_id_seq; Type: SEQUENCE; Schema: distribuidor; Owner: -
--

CREATE SEQUENCE distribuidor.devedores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: devedores_id_seq; Type: SEQUENCE OWNED BY; Schema: distribuidor; Owner: -
--

ALTER SEQUENCE distribuidor.devedores_id_seq OWNED BY distribuidor.devedores.id;


--
-- Name: faixa_custas; Type: TABLE; Schema: distribuidor; Owner: -
--

CREATE TABLE distribuidor.faixa_custas (
    id bigint NOT NULL,
    sequencial integer NOT NULL,
    tipo character varying(1) NOT NULL,
    valor numeric(12,2),
    numero_cartorios integer,
    quantidade_dia numeric(12,2),
    limite_inferior numeric(12,2) NOT NULL,
    limite_superior numeric(12,2) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: faixa_custas_id_seq; Type: SEQUENCE; Schema: distribuidor; Owner: -
--

CREATE SEQUENCE distribuidor.faixa_custas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: faixa_custas_id_seq; Type: SEQUENCE OWNED BY; Schema: distribuidor; Owner: -
--

ALTER SEQUENCE distribuidor.faixa_custas_id_seq OWNED BY distribuidor.faixa_custas.id;


--
-- Name: feriados; Type: TABLE; Schema: distribuidor; Owner: -
--

CREATE TABLE distribuidor.feriados (
    id bigint NOT NULL,
    data date NOT NULL,
    descricao character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: feriados_id_seq; Type: SEQUENCE; Schema: distribuidor; Owner: -
--

CREATE SEQUENCE distribuidor.feriados_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feriados_id_seq; Type: SEQUENCE OWNED BY; Schema: distribuidor; Owner: -
--

ALTER SEQUENCE distribuidor.feriados_id_seq OWNED BY distribuidor.feriados.id;


--
-- Name: irregularidades; Type: TABLE; Schema: distribuidor; Owner: -
--

CREATE TABLE distribuidor.irregularidades (
    id bigint NOT NULL,
    codigo integer NOT NULL,
    descricao character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: irregularidades_id_seq; Type: SEQUENCE; Schema: distribuidor; Owner: -
--

CREATE SEQUENCE distribuidor.irregularidades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: irregularidades_id_seq; Type: SEQUENCE OWNED BY; Schema: distribuidor; Owner: -
--

ALTER SEQUENCE distribuidor.irregularidades_id_seq OWNED BY distribuidor.irregularidades.id;


--
-- Name: oficio_distribuidores; Type: TABLE; Schema: distribuidor; Owner: -
--

CREATE TABLE distribuidor.oficio_distribuidores (
    id bigint NOT NULL,
    codigo_legado character varying(6),
    nome character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: oficio_distribuidores_id_seq; Type: SEQUENCE; Schema: distribuidor; Owner: -
--

CREATE SEQUENCE distribuidor.oficio_distribuidores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oficio_distribuidores_id_seq; Type: SEQUENCE OWNED BY; Schema: distribuidor; Owner: -
--

ALTER SEQUENCE distribuidor.oficio_distribuidores_id_seq OWNED BY distribuidor.oficio_distribuidores.id;


--
-- Name: remessas; Type: TABLE; Schema: distribuidor; Owner: -
--

CREATE TABLE distribuidor.remessas (
    id bigint NOT NULL,
    nome_arquivo character varying NOT NULL,
    banco_id bigint,
    apresentante_id bigint,
    numero_remessa character varying,
    quantidade_registros_transacao integer,
    quantidade_titulos integer,
    quantidade_indicacoes integer,
    quantidade_originais integer,
    status character varying DEFAULT 'pendente'::character varying NOT NULL,
    mensagem_erro text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: remessas_id_seq; Type: SEQUENCE; Schema: distribuidor; Owner: -
--

CREATE SEQUENCE distribuidor.remessas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: remessas_id_seq; Type: SEQUENCE OWNED BY; Schema: distribuidor; Owner: -
--

ALTER SEQUENCE distribuidor.remessas_id_seq OWNED BY distribuidor.remessas.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: distribuidor; Owner: -
--

CREATE TABLE distribuidor.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: tipo_titulos; Type: TABLE; Schema: distribuidor; Owner: -
--

CREATE TABLE distribuidor.tipo_titulos (
    id bigint NOT NULL,
    codigo_legado character varying(2) NOT NULL,
    descricao character varying NOT NULL,
    abreviatura character varying(3) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: tipo_titulos_id_seq; Type: SEQUENCE; Schema: distribuidor; Owner: -
--

CREATE SEQUENCE distribuidor.tipo_titulos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipo_titulos_id_seq; Type: SEQUENCE OWNED BY; Schema: distribuidor; Owner: -
--

ALTER SEQUENCE distribuidor.tipo_titulos_id_seq OWNED BY distribuidor.tipo_titulos.id;


--
-- Name: titulos; Type: TABLE; Schema: distribuidor; Owner: -
--

CREATE TABLE distribuidor.titulos (
    id bigint NOT NULL,
    protocolo_original character varying,
    numero_protocolo_distribuido character varying,
    devedor_id bigint NOT NULL,
    tipo_documento_devedor character varying(4) NOT NULL,
    cpf_cnpj_devedor character varying(14) NOT NULL,
    nome_devedor character varying,
    endereco_devedor character varying,
    cep_devedor character varying,
    cidade_devedor character varying,
    uf_devedor character varying(2),
    tipo_titulo_id bigint,
    numero_titulo character varying NOT NULL,
    data_emissao date,
    data_vencimento date,
    data_recebimento date NOT NULL,
    data_distribuicao date,
    valor numeric(12,2) NOT NULL,
    apresentante_id bigint,
    cedente character varying,
    nome_sacador character varying,
    documento_sacador character varying,
    endereco_sacador character varying,
    cep_sacador character varying,
    cidade_sacador character varying,
    uf_sacador character varying(2),
    cartorio_id bigint,
    oficio_distribuidor_id bigint,
    codigo_banco character varying,
    codigo_agencia character varying,
    status character varying DEFAULT 'G'::character varying NOT NULL,
    efeito_falencia boolean DEFAULT false NOT NULL,
    irregularidade_id bigint,
    tipo_ocorrencia character varying(1),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    remessa_id bigint
);


--
-- Name: titulos_id_seq; Type: SEQUENCE; Schema: distribuidor; Owner: -
--

CREATE SEQUENCE distribuidor.titulos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: titulos_id_seq; Type: SEQUENCE OWNED BY; Schema: distribuidor; Owner: -
--

ALTER SEQUENCE distribuidor.titulos_id_seq OWNED BY distribuidor.titulos.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('distribuidor.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('distribuidor.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('distribuidor.active_storage_variant_records_id_seq'::regclass);


--
-- Name: apresentantes id; Type: DEFAULT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.apresentantes ALTER COLUMN id SET DEFAULT nextval('distribuidor.apresentantes_id_seq'::regclass);


--
-- Name: bancos id; Type: DEFAULT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.bancos ALTER COLUMN id SET DEFAULT nextval('distribuidor.bancos_id_seq'::regclass);


--
-- Name: cartorios id; Type: DEFAULT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.cartorios ALTER COLUMN id SET DEFAULT nextval('distribuidor.cartorios_id_seq'::regclass);


--
-- Name: devedor_solidarios id; Type: DEFAULT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.devedor_solidarios ALTER COLUMN id SET DEFAULT nextval('distribuidor.devedor_solidarios_id_seq'::regclass);


--
-- Name: devedores id; Type: DEFAULT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.devedores ALTER COLUMN id SET DEFAULT nextval('distribuidor.devedores_id_seq'::regclass);


--
-- Name: faixa_custas id; Type: DEFAULT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.faixa_custas ALTER COLUMN id SET DEFAULT nextval('distribuidor.faixa_custas_id_seq'::regclass);


--
-- Name: feriados id; Type: DEFAULT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.feriados ALTER COLUMN id SET DEFAULT nextval('distribuidor.feriados_id_seq'::regclass);


--
-- Name: irregularidades id; Type: DEFAULT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.irregularidades ALTER COLUMN id SET DEFAULT nextval('distribuidor.irregularidades_id_seq'::regclass);


--
-- Name: oficio_distribuidores id; Type: DEFAULT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.oficio_distribuidores ALTER COLUMN id SET DEFAULT nextval('distribuidor.oficio_distribuidores_id_seq'::regclass);


--
-- Name: remessas id; Type: DEFAULT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.remessas ALTER COLUMN id SET DEFAULT nextval('distribuidor.remessas_id_seq'::regclass);


--
-- Name: tipo_titulos id; Type: DEFAULT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.tipo_titulos ALTER COLUMN id SET DEFAULT nextval('distribuidor.tipo_titulos_id_seq'::regclass);


--
-- Name: titulos id; Type: DEFAULT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.titulos ALTER COLUMN id SET DEFAULT nextval('distribuidor.titulos_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: apresentantes apresentantes_pkey; Type: CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.apresentantes
    ADD CONSTRAINT apresentantes_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: bancos bancos_pkey; Type: CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.bancos
    ADD CONSTRAINT bancos_pkey PRIMARY KEY (id);


--
-- Name: cartorios cartorios_pkey; Type: CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.cartorios
    ADD CONSTRAINT cartorios_pkey PRIMARY KEY (id);


--
-- Name: devedor_solidarios devedor_solidarios_pkey; Type: CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.devedor_solidarios
    ADD CONSTRAINT devedor_solidarios_pkey PRIMARY KEY (id);


--
-- Name: devedores devedores_pkey; Type: CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.devedores
    ADD CONSTRAINT devedores_pkey PRIMARY KEY (id);


--
-- Name: faixa_custas faixa_custas_pkey; Type: CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.faixa_custas
    ADD CONSTRAINT faixa_custas_pkey PRIMARY KEY (id);


--
-- Name: feriados feriados_pkey; Type: CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.feriados
    ADD CONSTRAINT feriados_pkey PRIMARY KEY (id);


--
-- Name: irregularidades irregularidades_pkey; Type: CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.irregularidades
    ADD CONSTRAINT irregularidades_pkey PRIMARY KEY (id);


--
-- Name: oficio_distribuidores oficio_distribuidores_pkey; Type: CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.oficio_distribuidores
    ADD CONSTRAINT oficio_distribuidores_pkey PRIMARY KEY (id);


--
-- Name: remessas remessas_pkey; Type: CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.remessas
    ADD CONSTRAINT remessas_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: tipo_titulos tipo_titulos_pkey; Type: CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.tipo_titulos
    ADD CONSTRAINT tipo_titulos_pkey PRIMARY KEY (id);


--
-- Name: titulos titulos_pkey; Type: CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.titulos
    ADD CONSTRAINT titulos_pkey PRIMARY KEY (id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON distribuidor.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON distribuidor.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON distribuidor.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON distribuidor.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_apresentantes_on_codigo_legado; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE UNIQUE INDEX index_apresentantes_on_codigo_legado ON distribuidor.apresentantes USING btree (codigo_legado);


--
-- Name: index_bancos_on_apresentante_id; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE INDEX index_bancos_on_apresentante_id ON distribuidor.bancos USING btree (apresentante_id);


--
-- Name: index_bancos_on_codigo_alfa; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE UNIQUE INDEX index_bancos_on_codigo_alfa ON distribuidor.bancos USING btree (codigo_alfa);


--
-- Name: index_bancos_on_codigo_legado; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE UNIQUE INDEX index_bancos_on_codigo_legado ON distribuidor.bancos USING btree (codigo_legado);


--
-- Name: index_cartorios_on_codigo_legado; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE UNIQUE INDEX index_cartorios_on_codigo_legado ON distribuidor.cartorios USING btree (codigo_legado);


--
-- Name: index_devedor_solidarios_on_devedor_id; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE INDEX index_devedor_solidarios_on_devedor_id ON distribuidor.devedor_solidarios USING btree (devedor_id);


--
-- Name: index_devedor_solidarios_on_titulo_and_devedor; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE UNIQUE INDEX index_devedor_solidarios_on_titulo_and_devedor ON distribuidor.devedor_solidarios USING btree (titulo_id, devedor_id);


--
-- Name: index_devedor_solidarios_on_titulo_id; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE INDEX index_devedor_solidarios_on_titulo_id ON distribuidor.devedor_solidarios USING btree (titulo_id);


--
-- Name: index_devedores_on_nome; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE INDEX index_devedores_on_nome ON distribuidor.devedores USING btree (nome);


--
-- Name: index_devedores_on_tipo_documento_and_cpf_cnpj; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE UNIQUE INDEX index_devedores_on_tipo_documento_and_cpf_cnpj ON distribuidor.devedores USING btree (tipo_documento, cpf_cnpj);


--
-- Name: index_faixa_custas_on_sequencial; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE UNIQUE INDEX index_faixa_custas_on_sequencial ON distribuidor.faixa_custas USING btree (sequencial);


--
-- Name: index_feriados_on_data; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE UNIQUE INDEX index_feriados_on_data ON distribuidor.feriados USING btree (data);


--
-- Name: index_irregularidades_on_codigo; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE UNIQUE INDEX index_irregularidades_on_codigo ON distribuidor.irregularidades USING btree (codigo);


--
-- Name: index_oficio_distribuidores_on_codigo_legado; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE UNIQUE INDEX index_oficio_distribuidores_on_codigo_legado ON distribuidor.oficio_distribuidores USING btree (codigo_legado);


--
-- Name: index_remessas_on_apresentante_id; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE INDEX index_remessas_on_apresentante_id ON distribuidor.remessas USING btree (apresentante_id);


--
-- Name: index_remessas_on_banco_id; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE INDEX index_remessas_on_banco_id ON distribuidor.remessas USING btree (banco_id);


--
-- Name: index_remessas_on_nome_arquivo; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE UNIQUE INDEX index_remessas_on_nome_arquivo ON distribuidor.remessas USING btree (nome_arquivo);


--
-- Name: index_tipo_titulos_on_abreviatura; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE UNIQUE INDEX index_tipo_titulos_on_abreviatura ON distribuidor.tipo_titulos USING btree (abreviatura);


--
-- Name: index_tipo_titulos_on_codigo_legado; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE UNIQUE INDEX index_tipo_titulos_on_codigo_legado ON distribuidor.tipo_titulos USING btree (codigo_legado);


--
-- Name: index_titulos_on_apresentante_id; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE INDEX index_titulos_on_apresentante_id ON distribuidor.titulos USING btree (apresentante_id);


--
-- Name: index_titulos_on_cartorio_id; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE INDEX index_titulos_on_cartorio_id ON distribuidor.titulos USING btree (cartorio_id);


--
-- Name: index_titulos_on_data_distribuicao; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE INDEX index_titulos_on_data_distribuicao ON distribuidor.titulos USING btree (data_distribuicao);


--
-- Name: index_titulos_on_data_recebimento; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE INDEX index_titulos_on_data_recebimento ON distribuidor.titulos USING btree (data_recebimento);


--
-- Name: index_titulos_on_devedor_id; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE INDEX index_titulos_on_devedor_id ON distribuidor.titulos USING btree (devedor_id);


--
-- Name: index_titulos_on_irregularidade_id; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE INDEX index_titulos_on_irregularidade_id ON distribuidor.titulos USING btree (irregularidade_id);


--
-- Name: index_titulos_on_numero_protocolo_distribuido; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE UNIQUE INDEX index_titulos_on_numero_protocolo_distribuido ON distribuidor.titulos USING btree (numero_protocolo_distribuido);


--
-- Name: index_titulos_on_numero_titulo; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE INDEX index_titulos_on_numero_titulo ON distribuidor.titulos USING btree (numero_titulo);


--
-- Name: index_titulos_on_oficio_distribuidor_id; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE INDEX index_titulos_on_oficio_distribuidor_id ON distribuidor.titulos USING btree (oficio_distribuidor_id);


--
-- Name: index_titulos_on_protocolo_original; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE UNIQUE INDEX index_titulos_on_protocolo_original ON distribuidor.titulos USING btree (protocolo_original);


--
-- Name: index_titulos_on_remessa_id; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE INDEX index_titulos_on_remessa_id ON distribuidor.titulos USING btree (remessa_id);


--
-- Name: index_titulos_on_tipo_titulo_id; Type: INDEX; Schema: distribuidor; Owner: -
--

CREATE INDEX index_titulos_on_tipo_titulo_id ON distribuidor.titulos USING btree (tipo_titulo_id);


--
-- Name: titulos fk_rails_3e82822bf3; Type: FK CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.titulos
    ADD CONSTRAINT fk_rails_3e82822bf3 FOREIGN KEY (tipo_titulo_id) REFERENCES distribuidor.tipo_titulos(id);


--
-- Name: titulos fk_rails_505caea88e; Type: FK CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.titulos
    ADD CONSTRAINT fk_rails_505caea88e FOREIGN KEY (irregularidade_id) REFERENCES distribuidor.irregularidades(id);


--
-- Name: remessas fk_rails_5676734875; Type: FK CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.remessas
    ADD CONSTRAINT fk_rails_5676734875 FOREIGN KEY (banco_id) REFERENCES distribuidor.bancos(id);


--
-- Name: titulos fk_rails_683f443bcf; Type: FK CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.titulos
    ADD CONSTRAINT fk_rails_683f443bcf FOREIGN KEY (remessa_id) REFERENCES distribuidor.remessas(id);


--
-- Name: remessas fk_rails_7cd0eae697; Type: FK CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.remessas
    ADD CONSTRAINT fk_rails_7cd0eae697 FOREIGN KEY (apresentante_id) REFERENCES distribuidor.apresentantes(id);


--
-- Name: titulos fk_rails_8b7717a836; Type: FK CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.titulos
    ADD CONSTRAINT fk_rails_8b7717a836 FOREIGN KEY (devedor_id) REFERENCES distribuidor.devedores(id);


--
-- Name: titulos fk_rails_8bf4034534; Type: FK CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.titulos
    ADD CONSTRAINT fk_rails_8bf4034534 FOREIGN KEY (cartorio_id) REFERENCES distribuidor.cartorios(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES distribuidor.active_storage_blobs(id);


--
-- Name: titulos fk_rails_9abfdcf37f; Type: FK CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.titulos
    ADD CONSTRAINT fk_rails_9abfdcf37f FOREIGN KEY (apresentante_id) REFERENCES distribuidor.apresentantes(id);


--
-- Name: devedor_solidarios fk_rails_9d1c9db10c; Type: FK CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.devedor_solidarios
    ADD CONSTRAINT fk_rails_9d1c9db10c FOREIGN KEY (titulo_id) REFERENCES distribuidor.titulos(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES distribuidor.active_storage_blobs(id);


--
-- Name: devedor_solidarios fk_rails_d6a1a763ee; Type: FK CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.devedor_solidarios
    ADD CONSTRAINT fk_rails_d6a1a763ee FOREIGN KEY (devedor_id) REFERENCES distribuidor.devedores(id);


--
-- Name: titulos fk_rails_d980babd0e; Type: FK CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.titulos
    ADD CONSTRAINT fk_rails_d980babd0e FOREIGN KEY (oficio_distribuidor_id) REFERENCES distribuidor.oficio_distribuidores(id);


--
-- Name: bancos fk_rails_fc3f5bb7be; Type: FK CONSTRAINT; Schema: distribuidor; Owner: -
--

ALTER TABLE ONLY distribuidor.bancos
    ADD CONSTRAINT fk_rails_fc3f5bb7be FOREIGN KEY (apresentante_id) REFERENCES distribuidor.apresentantes(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO distribuidor;

INSERT INTO "schema_migrations" (version) VALUES
('20260721194014'),
('20260721193611'),
('20260721193330'),
('20260721192532'),
('20260721192515'),
('20260721192455'),
('20260721185149'),
('20260721185147'),
('20260721185143'),
('20260721185140'),
('20260721185136'),
('20260721185134'),
('20260721185130'),
('20260721185128'),
('20260721185125'),
('20260721185121'),
('20260721185120');

