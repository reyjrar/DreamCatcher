CREATE TABLE list
(
  id serial NOT NULL,
  "name" TEXT NOT NULL,
  type_id smallint NOT NULL,
  track BOOLEAN NOT NULL DEFAULT false,
  can_refresh boolean NOT NULL DEFAULT false,
  refresh_url TEXT,
  refresh_every interval DEFAULT '7 days'::interval,
  refresh_last_ts timestamp without time zone,
  CONSTRAINT list_pkey PRIMARY KEY (id),
  CONSTRAINT list_fki_type FOREIGN KEY (type_id)
      REFERENCES list_type (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE SET NULL
)
WITH (
  OIDS=FALSE
);
