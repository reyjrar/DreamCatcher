CREATE OR REPLACE FUNCTION find_or_create_conversation(text, text)
  RETURNS conversation AS
$BODY$DECLARE
	in_client_ip inet := CAST($1 as inet);
	in_server_ip inet := CAST($2 as inet);
	var_client_id BIGINT := 0;
	var_server_id BIGINT := 0;
	var_client_server_id BIGINT := 0;
	var_client_is_server BOOLEAN := FALSE;
	var_convo_id BIGINT;
	out_convo_row conversation;
BEGIN
	-- Find the Client ID
	select into var_client_id, var_client_server_id id, role_server_id
	from client where ip = in_client_ip;

	IF NOT FOUND THEN
		insert into client ( ip ) values ( in_client_ip );
		select currval('client_id_seq') into var_client_id;
	ELSE
		var_client_is_server := var_client_server_id is not null;
		update client set last_ts = NOW(), reference_count = reference_count + 1 where id = var_client_id;
	END IF;

	-- Find the Server ID
	select id into var_server_id from server where ip = in_server_ip;

	IF NOT FOUND THEN
		insert into server ( ip ) values ( in_server_ip );
		select currval('server_id_seq') into var_server_id;
	ELSE
		update server set last_ts = NOW(), reference_count = reference_count + 1 where id = var_server_id;
	END IF;

	-- Find the Conversation Record
	select into var_convo_id id from conversation
		where client_id = var_client_id and server_id = var_server_id;

	IF NOT FOUND THEN
		insert into conversation ( client_id, server_id, client_is_server )
			values ( var_client_id, var_server_id, var_client_is_server );
		select currval('conversation_id_seq') into var_convo_id;
	ELSE
		update conversation set last_ts = NOW(), reference_count = reference_count + 1 where id = var_convo_id;
	END IF;

	select * into out_convo_row from conversation where id = var_convo_id;
	RETURN out_convo_row;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
