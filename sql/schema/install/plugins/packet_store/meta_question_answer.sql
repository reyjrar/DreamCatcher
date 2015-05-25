-- Table: meta_question_answer

-- DROP TABLE meta_question_answer;

CREATE TABLE meta_question_answer
(
  question_id bigint NOT NULL,
  answer_id bigint NOT NULL,
  reference_count integer NOT NULL DEFAULT 1,
  first_ts timestamp without time zone NOT NULL DEFAULT now(),
  last_ts timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT meta_question_answer_pki PRIMARY KEY (question_id, answer_id),
  CONSTRAINT meta_question_answer_fki_answer FOREIGN KEY (answer_id)
      REFERENCES answer (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT meta_question_answer_fki_question FOREIGN KEY (question_id)
      REFERENCES question (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE
)
WITH (
  OIDS=FALSE
);
