-- Database generated with pgModeler (PostgreSQL Database Modeler).
-- pgModeler version: 1.1.3
-- PostgreSQL version: 15.0
-- Project Site: pgmodeler.io
-- Model Author: ---

-- Database creation must be performed outside a multi lined SQL file. 
-- These commands were put in this file only as a convenience.
-- 
-- object: pg_hw11 | type: DATABASE --
-- DROP DATABASE IF EXISTS pg_hw11;
CREATE DATABASE pg_hw11;
-- ddl-end --


-- object: public.vm | type: TABLE --
-- DROP TABLE IF EXISTS public.vm CASCADE;
CREATE TABLE public.vm (
	vm_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ,
	name varchar(255),
	ip inet,
	created_at date,
	CONSTRAINT vm_pk PRIMARY KEY (vm_id)
);
-- ddl-end --
COMMENT ON COLUMN public.vm.name IS E'VM name';
-- ddl-end --
ALTER TABLE public.vm OWNER TO postgres;
-- ddl-end --

-- object: public."user" | type: TABLE --
-- DROP TABLE IF EXISTS public."user" CASCADE;
CREATE TABLE public."user" (
	user_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ,
	login varchar(255),
	surname varchar(255),
	name varchar(255),
	lastname varchar(255),
	CONSTRAINT user_pk PRIMARY KEY (user_id)
);
-- ddl-end --
ALTER TABLE public."user" OWNER TO postgres;
-- ddl-end --

-- object: public.session | type: TABLE --
-- DROP TABLE IF EXISTS public.session CASCADE;
CREATE TABLE public.session (
	session_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ,
	start_at date,
	end_at date,
	ip inet,
	vm_id_vm bigint,
	user_id_user bigint,
	CONSTRAINT session_pk PRIMARY KEY (session_id)
);
-- ddl-end --
ALTER TABLE public.session OWNER TO postgres;
-- ddl-end --

-- object: vm_fk | type: CONSTRAINT --
-- ALTER TABLE public.session DROP CONSTRAINT IF EXISTS vm_fk CASCADE;
ALTER TABLE public.session ADD CONSTRAINT vm_fk FOREIGN KEY (vm_id_vm)
REFERENCES public.vm (vm_id) MATCH FULL
ON DELETE SET NULL ON UPDATE CASCADE;
-- ddl-end --

-- object: user_fk | type: CONSTRAINT --
-- ALTER TABLE public.session DROP CONSTRAINT IF EXISTS user_fk CASCADE;
ALTER TABLE public.session ADD CONSTRAINT user_fk FOREIGN KEY (user_id_user)
REFERENCES public."user" (user_id) MATCH FULL
ON DELETE SET NULL ON UPDATE CASCADE;
-- ddl-end --


