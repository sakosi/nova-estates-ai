--
-- PostgreSQL database dump
--

\restrict Y2wE7PqpYfEYAjovhmxno6Lg8KuCHpcp3eQ5yinIFSgloDMLKWoRVwytsByRhFT

-- Dumped from database version 17.12
-- Dumped by pg_dump version 18.6

-- Started on 2026-11-25 23:51:07 +05

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 22 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- TOC entry 4074 (class 0 OID 0)
-- Dependencies: 22
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 533 (class 1255 OID 18101)
-- Name: match_documents(extensions.vector, integer, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.match_documents(query_embedding extensions.vector, match_count integer DEFAULT 5, filter jsonb DEFAULT '{}'::jsonb) RETURNS TABLE(id bigint, content text, metadata jsonb, similarity double precision)
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog', 'extensions', 'public'
    AS $$
    SELECT
        d.id,
        d.content,
        d.metadata,
        1 - (d.embedding <=> query_embedding)
            AS similarity
    FROM public.documents AS d
    WHERE d.embedding IS NOT NULL
      AND d.metadata @> filter
    ORDER BY d.embedding <=> query_embedding
    LIMIT match_count;
$$;


--
-- TOC entry 534 (class 1255 OID 18103)
-- Name: save_lead(text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.save_lead(p_session_id text, p_profile jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    v_lead public.leads%ROWTYPE;
    v_score INT := 0;
    v_status TEXT;
BEGIN

    IF p_session_id IS NULL
       OR trim(p_session_id) = '' THEN
        RAISE EXCEPTION 'Session ID is required';
    END IF;

    IF p_profile IS NULL
       OR jsonb_typeof(p_profile) <> 'object' THEN
        RAISE EXCEPTION 'Invalid lead profile';
    END IF;

    -- Create or update lead
    INSERT INTO public.leads AS l (
        session_id,
        location,
        property_type,
        bedrooms,
        budget_max,
        purpose,
        timeline_days
    )
    VALUES (
        p_session_id,
        NULLIF(p_profile->>'location', ''),
        NULLIF(p_profile->>'property_type', ''),
        (p_profile->>'bedrooms')::INT,
        (p_profile->>'budget_max')::NUMERIC,
        NULLIF(p_profile->>'purpose', ''),
        (p_profile->>'timeline_days')::INT
    )

    ON CONFLICT (session_id)
    DO UPDATE SET
        location = COALESCE(
            EXCLUDED.location, l.location),
        property_type = COALESCE(
            EXCLUDED.property_type, l.property_type),
        bedrooms = COALESCE(
            EXCLUDED.bedrooms, l.bedrooms),
        budget_max = COALESCE(
            EXCLUDED.budget_max, l.budget_max),
        purpose = COALESCE(
            EXCLUDED.purpose, l.purpose),
        timeline_days = COALESCE(
            EXCLUDED.timeline_days, l.timeline_days)

    RETURNING * INTO v_lead;

    -- Calculate lead score
    IF v_lead.budget_max IS NOT NULL THEN
        v_score := v_score + 25;
    END IF;

    IF v_lead.location IS NOT NULL THEN
        v_score := v_score + 15;
    END IF;

    IF v_lead.property_type IS NOT NULL THEN
        v_score := v_score + 10;
    END IF;

    IF v_lead.bedrooms IS NOT NULL THEN
        v_score := v_score + 10;
    END IF;

    IF v_lead.purpose IS NOT NULL THEN
        v_score := v_score + 15;
    END IF;

    IF v_lead.timeline_days <= 30 THEN
        v_score := v_score + 25;
    ELSIF v_lead.timeline_days <= 90 THEN
        v_score := v_score + 15;
    ELSIF v_lead.timeline_days > 90 THEN
        v_score := v_score + 5;
    END IF;

    -- Classify lead
    v_status := CASE
        WHEN v_lead.status = 'converted'
            THEN 'converted'
        WHEN v_score >= 75 THEN 'hot'
        WHEN v_score >= 45 THEN 'warm'
        ELSE 'cold'
    END;

    UPDATE public.leads
    SET lead_score = v_score,
        status = v_status
    WHERE id = v_lead.id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'lead_id', v_lead.id,
        'lead_score', v_score,
        'status', v_status
    );

END;
$$;


--
-- TOC entry 532 (class 1255 OID 18099)
-- Name: update_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 294 (class 1259 OID 18056)
-- Name: crm_sync_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.crm_sync_log (
    id bigint NOT NULL,
    lead_id bigint NOT NULL,
    platform text DEFAULT 'google_sheets'::text NOT NULL,
    external_id text,
    action text NOT NULL,
    sync_status text DEFAULT 'pending'::text NOT NULL,
    error_message text,
    created_at timestamp with time zone DEFAULT now(),
    synced_at timestamp with time zone,
    CONSTRAINT crm_sync_log_action_check CHECK ((action = ANY (ARRAY['create'::text, 'update'::text]))),
    CONSTRAINT crm_sync_log_sync_status_check CHECK ((sync_status = ANY (ARRAY['pending'::text, 'success'::text, 'failed'::text])))
);
ALTER TABLE ONLY public.crm_sync_log ALTER COLUMN id SET (pg_attver=118341416);
ALTER TABLE ONLY public.crm_sync_log ALTER COLUMN lead_id SET (pg_attver=118341416);
ALTER TABLE ONLY public.crm_sync_log ALTER COLUMN platform SET (pg_attver=118341416);
ALTER TABLE ONLY public.crm_sync_log ALTER COLUMN external_id SET (pg_attver=118341416);
ALTER TABLE ONLY public.crm_sync_log ALTER COLUMN action SET (pg_attver=118341416);
ALTER TABLE ONLY public.crm_sync_log ALTER COLUMN sync_status SET (pg_attver=118341416);
ALTER TABLE ONLY public.crm_sync_log ALTER COLUMN error_message SET (pg_attver=118341416);
ALTER TABLE ONLY public.crm_sync_log ALTER COLUMN created_at SET (pg_attver=118341416);
ALTER TABLE ONLY public.crm_sync_log ALTER COLUMN synced_at SET (pg_attver=118341416);


--
-- TOC entry 293 (class 1259 OID 18055)
-- Name: crm_sync_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.crm_sync_log ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.crm_sync_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 290 (class 1259 OID 18023)
-- Name: documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documents (
    id bigint NOT NULL,
    content text NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    embedding extensions.vector(3072),
    created_at timestamp with time zone DEFAULT now()
);
ALTER TABLE ONLY public.documents ALTER COLUMN id SET (pg_attver=118262976);
ALTER TABLE ONLY public.documents ALTER COLUMN content SET (pg_attver=118262976);
ALTER TABLE ONLY public.documents ALTER COLUMN metadata SET (pg_attver=118262976);
ALTER TABLE ONLY public.documents ALTER COLUMN embedding SET (pg_attver=118262976);
ALTER TABLE ONLY public.documents ALTER COLUMN created_at SET (pg_attver=118262976);


--
-- TOC entry 289 (class 1259 OID 18022)
-- Name: documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4075 (class 0 OID 0)
-- Dependencies: 289
-- Name: documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.documents_id_seq OWNED BY public.documents.id;


--
-- TOC entry 296 (class 1259 OID 18074)
-- Name: follow_ups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.follow_ups (
    id bigint NOT NULL,
    lead_id bigint NOT NULL,
    channel text DEFAULT 'email'::text NOT NULL,
    message text NOT NULL,
    scheduled_at timestamp with time zone NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    sent_at timestamp with time zone,
    CONSTRAINT follow_ups_channel_check CHECK ((channel = ANY (ARRAY['email'::text, 'telegram'::text, 'whatsapp'::text]))),
    CONSTRAINT follow_ups_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'sent'::text, 'failed'::text, 'cancelled'::text])))
);
ALTER TABLE ONLY public.follow_ups ALTER COLUMN id SET (pg_attver=118384560);
ALTER TABLE ONLY public.follow_ups ALTER COLUMN lead_id SET (pg_attver=118384560);
ALTER TABLE ONLY public.follow_ups ALTER COLUMN channel SET (pg_attver=118384560);
ALTER TABLE ONLY public.follow_ups ALTER COLUMN message SET (pg_attver=118384560);
ALTER TABLE ONLY public.follow_ups ALTER COLUMN scheduled_at SET (pg_attver=118384560);
ALTER TABLE ONLY public.follow_ups ALTER COLUMN status SET (pg_attver=118384560);
ALTER TABLE ONLY public.follow_ups ALTER COLUMN created_at SET (pg_attver=118384560);
ALTER TABLE ONLY public.follow_ups ALTER COLUMN sent_at SET (pg_attver=118384560);


--
-- TOC entry 295 (class 1259 OID 18073)
-- Name: follow_ups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.follow_ups ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.follow_ups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 284 (class 1259 OID 17980)
-- Name: leads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leads (
    id bigint NOT NULL,
    session_id text NOT NULL,
    full_name text,
    email text,
    phone text,
    location text,
    property_type text,
    bedrooms integer,
    budget_max numeric(14,2),
    purpose text,
    timeline_days integer,
    lead_score integer DEFAULT 0 NOT NULL,
    status text DEFAULT 'new'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    contact_consent boolean DEFAULT false NOT NULL,
    crm_external_id text,
    CONSTRAINT leads_bedrooms_check CHECK ((bedrooms >= 0)),
    CONSTRAINT leads_budget_max_check CHECK ((budget_max > (0)::numeric)),
    CONSTRAINT leads_lead_score_check CHECK (((lead_score >= 0) AND (lead_score <= 100))),
    CONSTRAINT leads_status_check CHECK ((status = ANY (ARRAY['new'::text, 'cold'::text, 'warm'::text, 'hot'::text, 'converted'::text]))),
    CONSTRAINT leads_timeline_days_check CHECK ((timeline_days >= 0))
);
ALTER TABLE ONLY public.leads ALTER COLUMN id SET (pg_attver=118130136);
ALTER TABLE ONLY public.leads ALTER COLUMN session_id SET (pg_attver=118130136);
ALTER TABLE ONLY public.leads ALTER COLUMN full_name SET (pg_attver=118130136);
ALTER TABLE ONLY public.leads ALTER COLUMN email SET (pg_attver=118130136);
ALTER TABLE ONLY public.leads ALTER COLUMN phone SET (pg_attver=118130136);
ALTER TABLE ONLY public.leads ALTER COLUMN location SET (pg_attver=118130136);
ALTER TABLE ONLY public.leads ALTER COLUMN property_type SET (pg_attver=118130136);
ALTER TABLE ONLY public.leads ALTER COLUMN bedrooms SET (pg_attver=118130136);
ALTER TABLE ONLY public.leads ALTER COLUMN budget_max SET (pg_attver=118130136);
ALTER TABLE ONLY public.leads ALTER COLUMN purpose SET (pg_attver=118130136);
ALTER TABLE ONLY public.leads ALTER COLUMN timeline_days SET (pg_attver=118130136);
ALTER TABLE ONLY public.leads ALTER COLUMN lead_score SET (pg_attver=118130136);
ALTER TABLE ONLY public.leads ALTER COLUMN status SET (pg_attver=118130136);
ALTER TABLE ONLY public.leads ALTER COLUMN created_at SET (pg_attver=118130136);
ALTER TABLE ONLY public.leads ALTER COLUMN updated_at SET (pg_attver=118130136);
ALTER TABLE ONLY public.leads ALTER COLUMN contact_consent SET (pg_attver=118187368);
ALTER TABLE ONLY public.leads ALTER COLUMN crm_external_id SET (pg_attver=118189648);


--
-- TOC entry 283 (class 1259 OID 17979)
-- Name: leads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.leads ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.leads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 288 (class 1259 OID 18014)
-- Name: n8n_chat_histories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.n8n_chat_histories (
    id integer NOT NULL,
    session_id character varying(255) NOT NULL,
    message jsonb NOT NULL
);
ALTER TABLE ONLY public.n8n_chat_histories ALTER COLUMN id SET (pg_attver=118236208);
ALTER TABLE ONLY public.n8n_chat_histories ALTER COLUMN session_id SET (pg_attver=118236208);
ALTER TABLE ONLY public.n8n_chat_histories ALTER COLUMN message SET (pg_attver=118236208);


--
-- TOC entry 287 (class 1259 OID 18013)
-- Name: n8n_chat_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.n8n_chat_histories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4076 (class 0 OID 0)
-- Dependencies: 287
-- Name: n8n_chat_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.n8n_chat_histories_id_seq OWNED BY public.n8n_chat_histories.id;


--
-- TOC entry 286 (class 1259 OID 18000)
-- Name: properties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties (
    id bigint NOT NULL,
    title text NOT NULL,
    location text NOT NULL,
    property_type text NOT NULL,
    bedrooms integer,
    price numeric(14,2) NOT NULL,
    area_sqm numeric(8,2),
    description text,
    status text DEFAULT 'available'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT properties_area_sqm_check CHECK ((area_sqm > (0)::numeric)),
    CONSTRAINT properties_bedrooms_check CHECK ((bedrooms >= 0)),
    CONSTRAINT properties_price_check CHECK ((price > (0)::numeric)),
    CONSTRAINT properties_status_check CHECK ((status = ANY (ARRAY['available'::text, 'reserved'::text, 'sold'::text])))
);
ALTER TABLE ONLY public.properties ALTER COLUMN id SET (pg_attver=118197440);
ALTER TABLE ONLY public.properties ALTER COLUMN title SET (pg_attver=118197440);
ALTER TABLE ONLY public.properties ALTER COLUMN location SET (pg_attver=118197440);
ALTER TABLE ONLY public.properties ALTER COLUMN property_type SET (pg_attver=118197440);
ALTER TABLE ONLY public.properties ALTER COLUMN bedrooms SET (pg_attver=118197440);
ALTER TABLE ONLY public.properties ALTER COLUMN price SET (pg_attver=118197440);
ALTER TABLE ONLY public.properties ALTER COLUMN area_sqm SET (pg_attver=118197440);
ALTER TABLE ONLY public.properties ALTER COLUMN description SET (pg_attver=118197440);
ALTER TABLE ONLY public.properties ALTER COLUMN status SET (pg_attver=118197440);
ALTER TABLE ONLY public.properties ALTER COLUMN created_at SET (pg_attver=118197440);


--
-- TOC entry 285 (class 1259 OID 17999)
-- Name: properties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.properties ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.properties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 292 (class 1259 OID 18034)
-- Name: recommendations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recommendations (
    id bigint NOT NULL,
    lead_id bigint NOT NULL,
    property_id bigint NOT NULL,
    reason text,
    match_score integer,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT recommendations_match_score_check CHECK (((match_score >= 0) AND (match_score <= 100)))
);
ALTER TABLE ONLY public.recommendations ALTER COLUMN id SET (pg_attver=118292712);
ALTER TABLE ONLY public.recommendations ALTER COLUMN lead_id SET (pg_attver=118292712);
ALTER TABLE ONLY public.recommendations ALTER COLUMN property_id SET (pg_attver=118292712);
ALTER TABLE ONLY public.recommendations ALTER COLUMN reason SET (pg_attver=118292712);
ALTER TABLE ONLY public.recommendations ALTER COLUMN match_score SET (pg_attver=118292712);
ALTER TABLE ONLY public.recommendations ALTER COLUMN created_at SET (pg_attver=118292712);


--
-- TOC entry 291 (class 1259 OID 18033)
-- Name: recommendations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.recommendations ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.recommendations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 3858 (class 2604 OID 18026)
-- Name: documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents ALTER COLUMN id SET DEFAULT nextval('public.documents_id_seq'::regclass);


--
-- TOC entry 3857 (class 2604 OID 18017)
-- Name: n8n_chat_histories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.n8n_chat_histories ALTER COLUMN id SET DEFAULT nextval('public.n8n_chat_histories_id_seq'::regclass);


--
-- TOC entry 3902 (class 2606 OID 18067)
-- Name: crm_sync_log crm_sync_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crm_sync_log
    ADD CONSTRAINT crm_sync_log_pkey PRIMARY KEY (id);


--
-- TOC entry 3895 (class 2606 OID 18032)
-- Name: documents documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);


--
-- TOC entry 3905 (class 2606 OID 18085)
-- Name: follow_ups follow_ups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follow_ups
    ADD CONSTRAINT follow_ups_pkey PRIMARY KEY (id);


--
-- TOC entry 3885 (class 2606 OID 17995)
-- Name: leads leads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_pkey PRIMARY KEY (id);


--
-- TOC entry 3887 (class 2606 OID 17997)
-- Name: leads leads_session_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_session_id_key UNIQUE (session_id);


--
-- TOC entry 3893 (class 2606 OID 18021)
-- Name: n8n_chat_histories n8n_chat_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.n8n_chat_histories
    ADD CONSTRAINT n8n_chat_histories_pkey PRIMARY KEY (id);


--
-- TOC entry 3890 (class 2606 OID 18012)
-- Name: properties properties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties
    ADD CONSTRAINT properties_pkey PRIMARY KEY (id);


--
-- TOC entry 3898 (class 2606 OID 18044)
-- Name: recommendations recommendations_lead_id_property_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recommendations
    ADD CONSTRAINT recommendations_lead_id_property_id_key UNIQUE (lead_id, property_id);


--
-- TOC entry 3900 (class 2606 OID 18042)
-- Name: recommendations recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recommendations
    ADD CONSTRAINT recommendations_pkey PRIMARY KEY (id);


--
-- TOC entry 3891 (class 1259 OID 18094)
-- Name: idx_chat_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_chat_session ON public.n8n_chat_histories USING btree (session_id, id);


--
-- TOC entry 3903 (class 1259 OID 18096)
-- Name: idx_crm_lead; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_crm_lead ON public.crm_sync_log USING btree (lead_id);


--
-- TOC entry 3906 (class 1259 OID 18097)
-- Name: idx_followups_lead; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_followups_lead ON public.follow_ups USING btree (lead_id);


--
-- TOC entry 3907 (class 1259 OID 18098)
-- Name: idx_followups_schedule; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_followups_schedule ON public.follow_ups USING btree (status, scheduled_at);


--
-- TOC entry 3882 (class 1259 OID 18092)
-- Name: idx_leads_score; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_score ON public.leads USING btree (lead_score DESC);


--
-- TOC entry 3883 (class 1259 OID 18091)
-- Name: idx_leads_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_status ON public.leads USING btree (status);


--
-- TOC entry 3888 (class 1259 OID 18093)
-- Name: idx_properties_search; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_properties_search ON public.properties USING btree (location, bedrooms, price);


--
-- TOC entry 3896 (class 1259 OID 18095)
-- Name: idx_recommendations_property; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_recommendations_property ON public.recommendations USING btree (property_id);


--
-- TOC entry 3912 (class 2620 OID 18100)
-- Name: leads leads_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER leads_updated_at BEFORE UPDATE ON public.leads FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- TOC entry 3910 (class 2606 OID 18068)
-- Name: crm_sync_log crm_sync_log_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crm_sync_log
    ADD CONSTRAINT crm_sync_log_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- TOC entry 3911 (class 2606 OID 18086)
-- Name: follow_ups follow_ups_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follow_ups
    ADD CONSTRAINT follow_ups_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- TOC entry 3908 (class 2606 OID 18045)
-- Name: recommendations recommendations_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recommendations
    ADD CONSTRAINT recommendations_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- TOC entry 3909 (class 2606 OID 18050)
-- Name: recommendations recommendations_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recommendations
    ADD CONSTRAINT recommendations_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties(id) ON DELETE CASCADE;


--
-- TOC entry 4066 (class 0 OID 18056)
-- Dependencies: 294
-- Name: crm_sync_log; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.crm_sync_log ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4064 (class 0 OID 18023)
-- Dependencies: 290
-- Name: documents; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4067 (class 0 OID 18074)
-- Dependencies: 296
-- Name: follow_ups; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.follow_ups ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4061 (class 0 OID 17980)
-- Dependencies: 284
-- Name: leads; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4063 (class 0 OID 18014)
-- Dependencies: 288
-- Name: n8n_chat_histories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.n8n_chat_histories ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4062 (class 0 OID 18000)
-- Dependencies: 286
-- Name: properties; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4065 (class 0 OID 18034)
-- Dependencies: 292
-- Name: recommendations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.recommendations ENABLE ROW LEVEL SECURITY;

-- Completed on 2026-11-25 23:51:53 +05

--
-- PostgreSQL database dump complete
--

\unrestrict Y2wE7PqpYfEYAjovhmxno6Lg8KuCHpcp3eQ5yinIFSgloDMLKWoRVwytsByRhFT

