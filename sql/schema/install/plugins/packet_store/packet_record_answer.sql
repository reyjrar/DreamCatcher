CREATE TABLE packet_record_answer
(
  id bigserial NOT NULL,
  first_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  last_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  "name" character varying(255) NOT NULL,
  "type" character varying(20) NOT NULL,
  "class" character varying(10) NOT NULL DEFAULT 'IN'::character varying,
  "value" character varying(255),
  opts character varying(255),
  reference_count bigint NOT NULL DEFAULT 0,
  CONSTRAINT packet_record_answer_pkey PRIMARY KEY (id),
  CONSTRAINT packet_record_answer_uniq UNIQUE (class, type, name, value)
)
WITH (
  OIDS=FALSE
);

CREATE INDEX packet_record_answer_idx_last_ts
  ON packet_record_answer
  USING btree
  (last_ts DESC);
