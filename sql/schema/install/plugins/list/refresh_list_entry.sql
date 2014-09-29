-- Function: refresh_list_entry(integer, text, text)

-- DROP FUNCTION refresh_list_entry(integer, text, text);

CREATE OR REPLACE FUNCTION refresh_list_entry(in_list_id integer, in_zone text, in_path text)
  RETURNS integer AS
$BODY$DECLARE
   var_zone TEXT;
   var_path ltree;
   out_entry_id BIGINT := 0;
BEGIN
    var_zone := lower( in_zone );
    var_path := lower( in_path );

    SELECT into out_entry_id id FROM list_entry
        WHERE list_id = in_list_id AND zone = var_zone;

    IF NOT FOUND THEN
        INSERT INTO list_entry ( list_id, zone, path, refreshed )
            VALUES ( in_list_id, var_zone, var_path, TRUE );
        SELECT currval('list_entry_id_seq') into out_entry_id;
    ELSE
        UPDATE list_entry SET refreshed = TRUE, last_ts = NOW()
            WHERE list_id = in_list_id AND zone = var_zone;
    END IF;
    UPDATE list SET refresh_last_ts = NOW() where id = in_list_id;
    RETURN out_entry_id;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
