CREATE TABLE packet_query
(
  id bigserial NOT NULL,
  client_id bigint NOT NULL,
  client_port bigint,
  server_id bigint NOT NULL,
  server_port bigint,
  query_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  query_serial bigint NOT NULL,
  conversation_id bigint NOT NULL,
  opcode TEXT NOT NULL,
  count_questions bigint NOT NULL,
  flag_recursive boolean NOT NULL DEFAULT false,
  flag_truncated boolean NOT NULL DEFAULT false,
  flag_checking boolean NOT NULL DEFAULT false,
  capture_time NUMERIC(16,6),
  CONSTRAINT packet_query_pkey PRIMARY KEY (id),
  CONSTRAINT packet_query_client_id_fkey FOREIGN KEY (client_id)
      REFERENCES client (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT packet_query_conversation_id_fkey FOREIGN KEY (conversation_id)
      REFERENCES conversation (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT packet_query_server_id_fkey FOREIGN KEY (server_id)
      REFERENCES server (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE
)
WITH (
  OIDS=FALSE
);

CREATE INDEX packet_query_idx_conversation_id
  ON packet_query
  USING btree (conversation_id);

CREATE INDEX packet_query_idx_query_ts
  ON packet_query
  USING btree (query_ts DESC NULLS LAST);

CREATE INDEX packet_query_idx_capture_time
  ON packet_query
  USING btree (capture_time DESC NULLS LAST);
