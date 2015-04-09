CREATE TABLE query
(
  id bigserial NOT NULL,
  client_id integer NOT NULL,
  client_port integer NOT NULL,
  server_id integer NOT NULL,
  server_port integer NOT NULL,
  query_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  query_serial integer NOT NULL,
  conversation_id bigint,
  opcode TEXT NOT NULL,
  count_questions integer NOT NULL DEFAULT 1,
  flag_recursive boolean NOT NULL DEFAULT false,
  flag_truncated boolean NOT NULL DEFAULT false,
  flag_checking boolean NOT NULL DEFAULT false,
  capture_time NUMERIC(16,6),
  CONSTRAINT query_pkey PRIMARY KEY (id),
  CONSTRAINT query_client_id_fkey FOREIGN KEY (client_id)
      REFERENCES client (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE SET NULL DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT query_conversation_id_fkey FOREIGN KEY (conversation_id)
      REFERENCES conversation (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE SET NULL DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT query_server_id_fkey FOREIGN KEY (server_id)
      REFERENCES server (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE SET NULL DEFERRABLE INITIALLY IMMEDIATE
)
WITH (
  OIDS=FALSE
);

CREATE INDEX query_idx_conversation_id
  ON query
  USING btree (conversation_id);

CREATE INDEX query_idx_query_ts
  ON query
  USING btree (query_ts DESC NULLS LAST);

CREATE INDEX query_idx_capture_time
  ON query
  USING btree (capture_time DESC NULLS LAST);
