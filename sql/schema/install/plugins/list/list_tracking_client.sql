CREATE TABLE list_tracking_client
(
  id serial not null,
  list_id integer NOT NULL,
  client_id integer NOT NULL,
  reference_count integer DEFAULT 0,
  first_ts timestamp without time zone NOT NULL DEFAULT now(),
  last_ts timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT list_tracking_client_pkey PRIMARY KEY (list_id, client_id),
  CONSTRAINT list_tracking_client_fki_list FOREIGN KEY (list_id)
      REFERENCES list (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT list_tracking_client_fki_client FOREIGN KEY (client_id)
      REFERENCES client (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE
)
WITH (
  OIDS=FALSE
);
