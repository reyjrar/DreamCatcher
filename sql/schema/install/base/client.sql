CREATE TABLE client
(
  id bigserial NOT NULL,
  ip inet NOT NULL,
  hostname character varying(255),
  first_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  last_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  is_local boolean NOT NULL DEFAULT false,
  role_server_id bigint,
  reference_count bigint NOT NULL DEFAULT 1,
  CONSTRAINT client_pkey PRIMARY KEY (id),
  CONSTRAINT client_role_server_id_fkey FOREIGN KEY (role_server_id)
      REFERENCES server (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE SET NULL DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT client_uniq_ip UNIQUE (ip)
)
WITH (
  OIDS=FALSE
);

CREATE INDEX client_idx_role_server_id
  ON client
  USING btree
  (role_server_id);
