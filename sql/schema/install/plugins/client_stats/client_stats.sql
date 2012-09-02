CREATE TABLE client_stats
(
  client_id bigint NOT NULL,
  "day" date NOT NULL,
  first_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  last_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  queries integer NOT NULL DEFAULT 0,
  answers integer NOT NULL DEFAULT 0,
  nx integer NOT NULL DEFAULT 0,
  errors integer NOT NULL DEFAULT 0,
  CONSTRAINT client_stats_pkey PRIMARY KEY (client_id, day),
  CONSTRAINT client_stats_client_id_fkey FOREIGN KEY (client_id)
      REFERENCES client (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE
)
WITH (
  OIDS=FALSE
);
