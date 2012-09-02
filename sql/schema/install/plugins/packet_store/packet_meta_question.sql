CREATE TABLE packet_meta_question
(
  query_id bigint NOT NULL,
  question_id bigint NOT NULL,
  CONSTRAINT packet_meta_question_pkey PRIMARY KEY (query_id, question_id),
  CONSTRAINT packet_meta_question_query_id_fkey FOREIGN KEY (query_id)
      REFERENCES packet_query (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT packet_meta_question_question_id_fkey FOREIGN KEY (question_id)
      REFERENCES packet_record_question (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE
)
WITH (
  OIDS=FALSE
);

CREATE INDEX packet_meta_question_idx_question
  ON packet_meta_question
  USING btree
  (question_id);
