CREATE OR REPLACE FUNCTION link_query_response(in_query_id bigint, in_response_id bigint, in_conversation_id bigint, in_timing numeric)
  RETURNS void AS
$BODY$
BEGIN
    PERFORM 1 FROM meta_query_response WHERE query_id = in_query_id AND response_id = in_response_id;

    IF NOT FOUND THEN
        INSERT INTO meta_query_response ( query_id, response_id, conversation_id, timing )
            VALUES ( in_query_id, in_response_id, in_conversation_id, in_timing );
    END IF;

	RETURN;
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
