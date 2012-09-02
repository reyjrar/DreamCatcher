CREATE TABLE list_entry
(
  id serial NOT NULL,
  list_id integer NOT NULL,
  "zone" character varying(255) NOT NULL,
  path ltree NOT NULL,
  refreshed boolean NOT NULL DEFAULT false,
  first_ts timestamp without time zone NOT NULL DEFAULT now(),
  last_ts timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT list_entry_pkey PRIMARY KEY (id),
  CONSTRAINT list_entry_fki_list FOREIGN KEY (list_id)
      REFERENCES list (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT list_entry_uniq UNIQUE (zone, list_id)
)
WITH (
  OIDS=FALSE
);

CREATE INDEX list_entry_idx_path_btree on list_entry using BTREE (path);
CREATE INDEX list_entry_idx_path_gist on list_entry using GIST (path);
