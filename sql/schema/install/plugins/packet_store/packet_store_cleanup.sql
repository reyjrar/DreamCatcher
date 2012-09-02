CREATE OR REPLACE FUNCTION packet_store_cleanup(text)
  RETURNS integer AS
$BODY$DECLARE
	in_interval INTERVAL := CAST($1 as INTERVAL);
	highest_id BIGINT;
	rows_deleted_query INTEGER;
	rows_deleted_response INTEGER;

BEGIN

	select id into highest_id from packet_query where query_ts > NOW() - in_interval order by id asc limit 1;
	DELETE from packet_query where id in (select id from packet_query where id < highest_id order by id asc limit 100000);
	GET DIAGNOSTICS rows_deleted_query := ROW_COUNT;

	select id into highest_id from packet_response where response_ts > NOW() - in_interval order by id asc limit 1;
	DELETE from packet_response where id in (select id from packet_response where id < highest_id order by id asc limit 100000);
	GET DIAGNOSTICS rows_deleted_response := ROW_COUNT;

	RETURN rows_deleted_query + rows_deleted_response;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
