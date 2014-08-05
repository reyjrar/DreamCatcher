-- Create the new function
CREATE OR REPLACE FUNCTION add_query(bigint, bigint, integer, bigint, integer, integer, TEXT, integer, boolean, boolean, boolean, numeric(16,6))
  RETURNS bigint AS
$BODY$DECLARE
	in_convo_id ALIAS FOR $1;
	in_client_id ALIAS FOR $2;
	in_client_port ALIAS FOR $3;
	in_server_id ALIAS FOR $4;
	in_server_port ALIAS FOR $5;
	in_query_serial ALIAS FOR $6;
	in_opcode ALIAS for $7;
	in_questions ALIAS for $8;
	in_recursive ALIAS for $9;
	in_truncated ALIAS for $10;
	in_checking ALIAS for $11;
	in_capture_time ALIAS for $12;
	out_query_id BIGINT := 0;
BEGIN
	-- Insert into packet_query
	insert into packet_query ( conversation_id, client_id, client_port, server_id, server_port,
				   query_serial, opcode, count_questions, flag_recursive, flag_truncated,
				   flag_checking, capture_time )
		values
				  ( in_convo_id, in_client_id, in_client_port, in_server_id, in_server_port,
				    in_query_serial, in_opcode, in_questions, in_recursive, in_truncated,
				    in_checking, in_capture_time );
	select currval('packet_query_id_seq') into out_query_id;

	RETURN out_query_id;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

