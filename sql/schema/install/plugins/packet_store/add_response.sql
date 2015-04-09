-- Create the New Function
CREATE OR REPLACE FUNCTION add_response(in_convo_id bigint, in_client_id integer, in_client_port integer, in_server_id integer, in_server_port integer, in_query_serial integer, in_opcode TEXT, in_status TEXT, in_size_answer integer, in_cnt_answer integer, in_cnt_additional integer, in_cnt_authority integer, in_cnt_question integer, in_authoritative boolean, in_authenticated boolean, in_truncated boolean, in_checking_desired boolean, in_recursion_desired boolean, in_recursion_available boolean, in_capture_time numeric(16,6))
  RETURNS bigint AS
$BODY$DECLARE
	out_response_id BIGINT := 0;
BEGIN
	-- Create Response
	insert into response ( conversation_id, client_id, client_port, server_id, server_port,
				      query_serial, opcode, status, size_answer, count_answer,
				      count_additional, count_authority, count_question,
				      flag_authoritative, flag_authenticated, flag_truncated,
				      flag_checking_desired, flag_recursion_desired, flag_recursion_available, capture_time )
		values ( in_convo_id, in_client_id, in_client_port, in_server_id, in_server_port,
			 in_query_serial, in_opcode, in_status, in_size_answer, in_cnt_answer,
			 in_cnt_additional, in_cnt_authority, in_cnt_question,
			 in_authoritative, in_authenticated, in_truncated,
			 in_checking_desired, in_recursion_desired, in_recursion_available, in_capture_time );

	-- Grab the ID
	select into out_response_id currval('response_id_seq');

	RETURN out_response_id;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

