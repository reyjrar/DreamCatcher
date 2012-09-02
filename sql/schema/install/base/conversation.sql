CREATE TABLE conversation
(
  id bigserial NOT NULL,
  server_id bigint NOT NULL,
  client_id bigint NOT NULL,
  first_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  last_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  client_is_server boolean NOT NULL DEFAULT false,
  CONSTRAINT conversation_pkey PRIMARY KEY (id),
  CONSTRAINT conversation_client_id_fkey FOREIGN KEY (client_id)
      REFERENCES client (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT conversation_server_id_fkey FOREIGN KEY (server_id)
      REFERENCES server (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT conversation_uniq_server_client UNIQUE (server_id, client_id)
)
WITH (
  OIDS=FALSE
);

CREATE INDEX conversation_idx_client_id
  ON conversation
  USING btree
  (client_id);

CREATE INDEX conversation_idx_server_id
  ON conversation
  USING btree
  (server_id);


