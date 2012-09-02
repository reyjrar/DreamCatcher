CREATE TABLE list_meta_answer
(
  list_id INTEGER NOT NULL,
  list_entry_id integer NOT NULL,
  answer_id bigint NOT NULL,
  CONSTRAINT list_meta_answer_pkey PRIMARY KEY (answer_id, list_entry_id),
  CONSTRAINT list_meta_answer_list FOREIGN KEY (list_id)
      REFERENCES list (id)
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT list_meta_answer_fki_list_entry FOREIGN KEY (list_entry_id)
      REFERENCES list_entry (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT list_meta_answer_fki_answer FOREIGN KEY (answer_id)
      REFERENCES packet_record_answer (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE
)
WITH (
  OIDS=FALSE
);

CREATE INDEX list_meta_answer_idx_list_entry
  ON list_meta_answer
  USING btree
  (list_entry_id);

CREATE INDEX fki_list_meta_answer_list_id ON list_meta_answer(list_id);
