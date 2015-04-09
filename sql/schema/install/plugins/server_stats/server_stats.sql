CREATE TABLE server_stats
(
  server_id integer NOT NULL,
  first_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  last_ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  queries bigint NOT NULL DEFAULT 0,
  answers bigint NOT NULL DEFAULT 0,
  nx integer NOT NULL DEFAULT 0,
  errors integer NOT NULL DEFAULT 0,
  "day" date NOT NULL DEFAULT ('now'::text)::date,
  CONSTRAINT server_stats_pkey PRIMARY KEY (server_id, day),
  CONSTRAINT server_stats_server_id_fkey FOREIGN KEY (server_id)
      REFERENCES server (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE
)
WITH (
  OIDS=FALSE
);
