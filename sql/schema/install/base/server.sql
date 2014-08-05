-- Server Table
CREATE TABLE server
(
  id bigserial NOT NULL,
  ip inet NOT NULL,
  hostname TEXT,
  first_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  last_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  is_authorized boolean NOT NULL DEFAULT false,
  reference_count bigint NOT NULL DEFAULT 1,
  CONSTRAINT server_pkey PRIMARY KEY (id),
  CONSTRAINT server_uniq_ip UNIQUE (ip)
)
WITH (
  OIDS=FALSE
);
