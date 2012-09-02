CREATE OR REPLACE FUNCTION link_query_response(in_query_id bigint, in_response_id bigint)
  RETURNS void AS
$BODY$BEGIN
	insert into packet_meta_query_response ( query_id, response_id ) values ( in_query_id, in_response_id );

	RETURN;
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
