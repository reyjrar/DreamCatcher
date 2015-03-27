CREATE OR REPLACE FUNCTION find_or_create_question(bigint, TEXT, TEXT, TEXT)
  RETURNS integer AS
$BODY$DECLARE
	in_query_id ALIAS FOR $1;
	in_class ALIAS FOR $2;
	in_type ALIAS FOR $3;
	in_name TEXT := LOWER($4);
	out_question_id INTEGER := 0;
BEGIN
	-- Find this Question
	select id into out_question_id from packet_record_question
		where class=in_class and type=in_type and name=in_name
	limit 1;  -- When we find it, stop.

	IF NOT FOUND THEN
		-- create it
		insert into packet_record_question ( class, type, name )
			values ( in_class, in_type, in_name );
		select currval('packet_record_question_id_seq') into out_question_id;
	END IF;

	-- Link the Query / Question
	insert into packet_meta_question ( query_id, question_id ) values ( in_query_id, out_question_id );
	-- Update the question tracking data
	update packet_record_question set last_ts=NOW(), reference_count=reference_count+1 where id=out_question_id;

	RETURN out_question_id;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
