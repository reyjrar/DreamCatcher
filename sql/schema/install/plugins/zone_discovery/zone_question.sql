CREATE TABLE zone_question
(
  zone_id bigint NOT NULL,
  question_id bigint NOT NULL,
  CONSTRAINT zone_question_pki_ids PRIMARY KEY (zone_id, question_id),
  CONSTRAINT zone_question_fki_question FOREIGN KEY (question_id)
      REFERENCES question (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT zone_question_fki_zone FOREIGN KEY (zone_id)
      REFERENCES "zone" (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE
)
WITH (
  OIDS=FALSE
);

CREATE INDEX fki_zone_question_fki_question
  ON zone_question
  USING btree
  (question_id);

