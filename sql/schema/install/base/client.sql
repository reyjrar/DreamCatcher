CREATE TABLE client
(
  id serial NOT NULL,
  ip inet NOT NULL,
  hostname TEXT,
  first_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  last_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  is_local boolean NOT NULL DEFAULT false,
  role_server_id integer,
  reference_count bigint NOT NULL DEFAULT 1,
  CONSTRAINT client_pkey PRIMARY KEY (id),
  CONSTRAINT client_role_server_id_fkey FOREIGN KEY (role_server_id)
      REFERENCES server (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE SET NULL DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT client_uniq_ip UNIQUE (ip)
)
WITH (
  OIDS=FALSE
);

CREATE INDEX client_idx_role_server_id
  ON client
  USING btree
  (role_server_id);
