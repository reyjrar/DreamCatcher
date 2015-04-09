CREATE TABLE meta_answer
(
  response_id bigint NOT NULL,
  answer_id bigint NOT NULL,
  ttl bigint NOT NULL,
  section TEXT NOT NULL DEFAULT 'answer'::text,
  CONSTRAINT meta_answer_pkey PRIMARY KEY (response_id, answer_id),
  CONSTRAINT meta_answer_answer_id_fkey FOREIGN KEY (answer_id)
      REFERENCES answer (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT meta_answer_response_id_fkey FOREIGN KEY (response_id)
      REFERENCES response (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE
)
WITH (
  OIDS=FALSE
);

CREATE INDEX meta_answer_idx_answer
  ON meta_answer
  USING btree
  (answer_id);
