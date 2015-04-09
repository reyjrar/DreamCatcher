CREATE TABLE anomaly_query
(
  query_id bigint NOT NULL,
  score integer NOT NULL DEFAULT 0,
  analysis jsonb,
  CONSTRAINT pki_anomaly_query PRIMARY KEY (query_id),
  CONSTRAINT fki_anomaly_query FOREIGN KEY (query_id)
      REFERENCES query (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE
)
WITH (
  OIDS=FALSE
);
