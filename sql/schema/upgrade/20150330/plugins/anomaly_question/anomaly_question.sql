CREATE TABLE anomaly_question
(
  question_id bigint NOT NULL,
  score integer NOT NULL DEFAULT 0,
  analysis jsonb,
  CONSTRAINT pki_anomaly_question PRIMARY KEY (question_id),
  CONSTRAINT fki_anomaly_question FOREIGN KEY (question_id)
      REFERENCES question (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE
)
WITH (
  OIDS=FALSE
);
