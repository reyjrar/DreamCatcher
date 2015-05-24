CREATE TABLE question
(
  id bigserial NOT NULL,
  first_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  last_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  "name" TEXT NOT NULL,
  "type" TEXT NOT NULL,
  "class" TEXT NOT NULL DEFAULT 'IN',
  reference_count bigint NOT NULL DEFAULT 0,
  CONSTRAINT question_pkey PRIMARY KEY (id),
  CONSTRAINT question_uniq UNIQUE ("class", "type", "name")
)
WITH (
  OIDS=FALSE
);

