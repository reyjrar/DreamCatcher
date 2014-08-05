CREATE TABLE packet_record_answer
(
  id bigserial NOT NULL,
  first_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  last_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  "name" TEXT NOT NULL,
  "type" TEXT NOT NULL,
  "class" TEXT NOT NULL DEFAULT 'IN',
  "value" TEXT,
  opts TEXT,
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
