-- Link zones to answers
CREATE OR REPLACE FUNCTION link_zone_answer(IN in_zone_id integer, IN in_answer_id integer)
	RETURNS boolean AS $$
DECLARE
	var_record_ts TIMESTAMP WITHOUT TIME ZONE;
	var_zone_ts TIMESTAMP WITHOUT TIME ZONE;
BEGIN
	-- Grab the time stamps;
	select last_ts into var_record_ts from answer where id=in_answer_id;
	select last_ts into var_zone_ts from zone where id=in_zone_id;

	-- Link Tables
	insert into zone_answer ( zone_id, answer_id ) values ( in_zone_id, in_answer_id );

	-- Update Metadata
	IF ( var_record_ts > var_zone_ts ) THEN
		update zone set last_ts=var_record_ts, reference_count=reference_count+1 where id=in_zone_id;
	ELSE
		update zone set reference_count=reference_count+1 where id=in_zone_id;
	END IF;
	RETURN TRUE;
END;
$$ LANGUAGE plpgsql VOLATILE;
