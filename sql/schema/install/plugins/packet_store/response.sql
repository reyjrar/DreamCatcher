CREATE TABLE response
(
  id bigserial NOT NULL,
  client_id integer NOT NULL,
  client_port integer NOT NULL,
  server_id integer NOT NULL,
  server_port integer NOT NULL,
  query_serial integer NOT NULL,
  response_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  conversation_id bigint,
  opcode TEXT NOT NULL,
  status TEXT NOT NULL,
  size_answer integer NOT NULL DEFAULT 0,
  count_answer integer NOT NULL DEFAULT 0,
  count_additional integer NOT NULL DEFAULT 0,
  count_authority integer NOT NULL DEFAULT 0,
  count_question integer NOT NULL DEFAULT 0,
  flag_authoritative boolean NOT NULL DEFAULT false,
  flag_authenticated boolean NOT NULL DEFAULT false,
  flag_truncated boolean NOT NULL DEFAULT false,
  flag_checking_desired boolean NOT NULL DEFAULT false,
  flag_recursion_desired boolean NOT NULL DEFAULT false,
  flag_recursion_available boolean NOT NULL DEFAULT false,
  capture_time NUMERIC(16,6),
  CONSTRAINT response_pkey PRIMARY KEY (id),
  CONSTRAINT response_client_id_fkey FOREIGN KEY (client_id)
      REFERENCES client (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT response_conversation_id_fkey FOREIGN KEY (conversation_id)
      REFERENCES conversation (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT response_server_id_fkey FOREIGN KEY (server_id)
      REFERENCES server (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE
)
WITH (
  OIDS=FALSE
);

CREATE INDEX response_idx_conversation_id
  ON response
  USING btree
  (conversation_id);

CREATE INDEX response_idx_query_serial
  ON response
  USING btree
  (query_serial);

CREATE INDEX response_idx_response_ts
  ON response
  USING btree
  (response_ts DESC NULLS LAST);

CREATE INDEX response_idx_capture_time
  ON response
  USING btree
  (capture_time DESC NULLS LAST);
