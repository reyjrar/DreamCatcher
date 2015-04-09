CREATE TABLE meta_question
(
  query_id bigint NOT NULL,
  question_id bigint NOT NULL,
  CONSTRAINT meta_question_pkey PRIMARY KEY (query_id, question_id),
  CONSTRAINT meta_question_query_id_fkey FOREIGN KEY (query_id)
      REFERENCES query (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT meta_question_question_id_fkey FOREIGN KEY (question_id)
      REFERENCES question (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE
)
WITH (
  OIDS=FALSE
);

CREATE INDEX meta_question_idx_question
  ON meta_question
  USING btree
  (question_id);
