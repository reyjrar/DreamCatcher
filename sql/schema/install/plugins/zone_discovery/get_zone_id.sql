-- Create the new function
CREATE OR REPLACE FUNCTION get_zone_id(in_zone_name character varying, in_zone_path character varying, in_first_ts TIMESTAMP WITHOUT TIME ZONE, in_last_ts TIMESTAMP WITHOUT TIME ZONE)
  RETURNS integer AS $$
DECLARE
	out_zone_id INTEGER;
	var_zone_name character varying;
	var_zone_path ltree;
BEGIN
	var_zone_name := lower( in_zone_name );
	var_zone_path := lower( in_zone_path );


	-- Check for this zone
	select into out_zone_id id from zone where name = var_zone_name;

	-- Update Last Timestamp
	IF FOUND THEN
		update zone set last_ts = in_last_ts where id=out_zone_id;
		RETURN out_zone_id;
	END IF;

	-- Create it if it doesn't exist
	INSERT INTO zone ( name, path, first_ts, last_ts ) values ( var_zone_name, var_zone_path, in_first_ts, in_last_ts );
	select into out_zone_id currval('zone_id_seq');

	RETURN out_zone_id;
END;
$$
  LANGUAGE plpgsql VOLATILE
  COST 100;

