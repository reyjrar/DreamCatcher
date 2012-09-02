CREATE TABLE packet_record_question
(
  id bigserial NOT NULL,
  first_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  last_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  "name" character varying(255) NOT NULL,
  "type" character varying(20) NOT NULL,
  "class" character varying(10) NOT NULL DEFAULT 'IN'::character varying,
  reference_count bigint NOT NULL DEFAULT 0,
  CONSTRAINT packet_record_question_pkey PRIMARY KEY (id),
  CONSTRAINT packet_record_question_uniq UNIQUE (class, type, name)
)
WITH (
  OIDS=FALSE
);

