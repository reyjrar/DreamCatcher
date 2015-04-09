CREATE OR REPLACE FUNCTION link_query_response(in_query_id bigint, in_response_id bigint)
  RETURNS void AS
$BODY$
BEGIN
    SELECT query_id FROM meta_query_response WHERE query_id = in_query_id AND reponse_id = in_response_id;

    IF NOT FOUND THEN
        INSERT INTO meta_query_response ( query_id, response_id ) VALUES ( in_query_id, in_response_id );
    END IF;

	RETURN;
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
