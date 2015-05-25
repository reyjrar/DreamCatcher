CREATE TABLE meta_query_response
(
  query_id bigint NOT NULL,
  response_id bigint NOT NULL,
  timing NUMERIC(11,6),
  conversation_id bigint NOT NULL,
  CONSTRAINT meta_query_response_pki PRIMARY KEY (query_id, response_id),
  CONSTRAINT meta_query_response_fki_query FOREIGN KEY (query_id)
      REFERENCES query (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT meta_query_response_fki_response FOREIGN KEY (response_id)
      REFERENCES response (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE
  CONSTRAINT meta_query_response_fki_conversation FOREIGN KEY (conversation_id)
      REFERENCES conversation (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE
)
WITH (
  OIDS=FALSE
);

-- Add Indices
CREATE INDEX meta_query_response_idx_response_id
  ON meta_query_response
  USING btree
  (response_id);
