CREATE OR REPLACE FUNCTION client_stats_update(in_client_id integer, in_queries integer, in_answers integer, in_nx integer, in_errors integer)
  RETURNS void AS
$BODY$DECLARE
	var_date DATE := CURRENT_DATE;
	var_found_id INTEGER;
BEGIN

	select client_id into var_found_id from client_stats where client_id = in_client_id and day = var_date;

	IF NOT FOUND THEN
		-- Do Insert
		insert into client_stats ( client_id, day, queries, answers, nx, errors )
			values ( in_client_id, var_date, in_queries, in_answers, in_nx, in_errors );
	ELSE
		-- Do Update
		update client_stats set queries=queries+in_queries, answers=answers+in_answers,
					nx=in_nx, errors=errors+in_errors, last_ts=NOW()
			where client_id = in_client_id and day=var_date;
	END IF;

	RETURN;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
