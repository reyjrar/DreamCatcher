CREATE TABLE list_tracking_client
(
  id serial not null,
  list_id integer NOT NULL,
  client_id integer NOT NULL,
  reference_count integer DEFAULT 0,
  first_ts timestamp without time zone NOT NULL DEFAULT now(),
  last_ts timestamp without time zone NOT NULL DEFAULT now(),
  since_ts timestamp without time zone NOT NULL DEFAULT now(),
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

CREATE OR REPLACE FUNCTION list_tracking_client(
    in_list_id integer,
    in_client_id integer,
    in_first_ts timestamp without time zone,
    in_last_ts timestamp without time zone,
    in_reference_count integer)
  RETURNS void AS
$BODY$
BEGIN
    PERFORM 1 FROM list_tracking_client WHERE list_id = in_list_id AND client_id = in_client_id;
    IF NOT FOUND THEN
        INSERT INTO list_tracking_client ( list_id, client_id, first_ts, last_ts, reference_count, since_ts )
            VALUES ( in_list_id, in_client_id, in_first_ts, in_last_ts, in_reference_count, in_first_ts );
    ELSE
    UPDATE list_tracking_client
        SET reference_count = in_reference_count,
            first_ts = (CASE WHEN in_first_ts < first_ts THEN in_first_ts ELSE first_ts END),
            last_ts = (CASE WHEN in_last_ts > last_ts THEN in_last_ts ELSE last_ts END),
            since_ts = in_first_ts
        WHERE list_id = in_list_id AND client_id = in_client_id;
    END IF;

    RETURN;
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
