CREATE TABLE packet_meta_answer
(
  response_id bigint NOT NULL,
  answer_id bigint NOT NULL,
  ttl bigint NOT NULL,
  section character(10) NOT NULL DEFAULT 'answer'::bpchar,
  CONSTRAINT packet_meta_answer_pkey PRIMARY KEY (response_id, answer_id),
  CONSTRAINT packet_meta_answer_answer_id_fkey FOREIGN KEY (answer_id)
      REFERENCES packet_record_answer (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT packet_meta_answer_response_id_fkey FOREIGN KEY (response_id)
      REFERENCES packet_response (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE
)
WITH (
  OIDS=FALSE
);

CREATE INDEX packet_meta_answer_idx_answer
  ON packet_meta_answer
  USING btree
  (answer_id);
