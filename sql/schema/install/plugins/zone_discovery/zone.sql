CREATE TABLE "zone"
(
  id bigserial NOT NULL,
  "name" character varying(255) NOT NULL,
  path ltree NOT NULL,
  reference_count BIGINT DEFAULT 0,
  first_ts TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
  last_ts TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
  CONSTRAINT zone_pki_id PRIMARY KEY (id),
  CONSTRAINT zone_uniq_name UNIQUE (name)
)
WITH (
  OIDS=FALSE
);

CREATE INDEX zone_idx_path_btree on zone using BTREE (path);
CREATE INDEX zone_idx_path_gist on zone using GIST (path);
CREATE INDEX zone_idx_name on zone using BTREE (name);
