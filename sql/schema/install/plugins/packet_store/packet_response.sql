CREATE TABLE packet_response
(
  id bigserial NOT NULL,
  client_id bigint NOT NULL,
  client_port bigint,
  server_id bigint NOT NULL,
  server_port bigint,
  query_serial bigint NOT NULL,
  response_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  conversation_id bigint NOT NULL,
  opcode character varying(12) NOT NULL,
  status character varying(20) NOT NULL,
  size_answer bigint NOT NULL DEFAULT 0,
  count_answer bigint NOT NULL DEFAULT 0,
  count_additional bigint NOT NULL DEFAULT 0,
  count_authority bigint NOT NULL DEFAULT 0,
  count_question bigint NOT NULL DEFAULT 0,
  flag_authoritative boolean NOT NULL DEFAULT false,
  flag_authenticated boolean NOT NULL DEFAULT false,
  flag_truncated boolean NOT NULL DEFAULT false,
  flag_checking_desired boolean NOT NULL DEFAULT false,
  flag_recursion_desired boolean NOT NULL DEFAULT false,
  flag_recursion_available boolean NOT NULL DEFAULT false,
  capture_time NUMERIC(16,6),
  CONSTRAINT packet_response_pkey PRIMARY KEY (id),
  CONSTRAINT packet_response_client_id_fkey FOREIGN KEY (client_id)
      REFERENCES client (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT packet_response_conversation_id_fkey FOREIGN KEY (conversation_id)
      REFERENCES conversation (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT packet_response_server_id_fkey FOREIGN KEY (server_id)
      REFERENCES server (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE
)
WITH (
  OIDS=FALSE
);

CREATE INDEX packet_response_idx_conversation_id
  ON packet_response
  USING btree
  (conversation_id);

CREATE INDEX packet_response_idx_query_serial
  ON packet_response
  USING btree
  (query_serial);

CREATE INDEX packet_response_idx_response_ts
  ON packet_response
  USING btree
  (response_ts DESC NULLS LAST);

CREATE INDEX packet_response_idx_capture_time
  ON packet_response
  USING btree
  (capture_time DESC NULLS LAST);
