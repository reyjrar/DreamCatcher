CREATE OR REPLACE FUNCTION client_stats_cleanup(text)
  RETURNS integer AS
$BODY$DECLARE
	in_interval INTERVAL := CAST($1 AS INTERVAL);
	rows_deleted INTEGER;
BEGIN

	DELETE FROM client_stats where day < NOW() - in_interval;
	GET DIAGNOSTICS rows_deleted := ROW_COUNT;

	RETURN rows_deleted;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
