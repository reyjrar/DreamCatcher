CREATE OR REPLACE FUNCTION server_stats_update(in_server_id integer, in_queries integer, in_answers integer, in_nx integer, in_errors integer)
  RETURNS void AS
$BODY$DECLARE
	var_date DATE := CURRENT_DATE;
	var_found_id INTEGER;
BEGIN

	select server_id into var_found_id from server_stats where server_id = in_server_id and day = var_date;

	IF NOT FOUND THEN
		-- Do Insert
		insert into server_stats ( server_id, day, queries, answers, nx, errors )
			values ( in_server_id, var_date, in_queries, in_answers, in_nx, in_errors );
	ELSE
		-- Do Update
		update server_stats set queries=queries+in_queries, answers=answers+in_answers,
					nx=in_nx, errors=errors+in_errors, last_ts=NOW()
			where server_id = in_server_id and day=var_date;
	END IF;

	RETURN;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
