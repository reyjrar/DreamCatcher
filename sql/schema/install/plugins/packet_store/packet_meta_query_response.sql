CREATE TABLE packet_meta_query_response
(
  query_id bigint NOT NULL,
  response_id bigint NOT NULL,
  CONSTRAINT packet_meta_query_response_pki PRIMARY KEY (query_id, response_id),
  CONSTRAINT packet_meta_query_response_fki_query FOREIGN KEY (query_id)
      REFERENCES packet_query (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT packet_meta_query_response_fki_response FOREIGN KEY (response_id)
      REFERENCES packet_response (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
)
WITH (
  OIDS=FALSE
);

-- Add Indices
CREATE INDEX packet_meta_query_response_idx_response_id
  ON packet_meta_query_response
  USING btree
  (response_id);
