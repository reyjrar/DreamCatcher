CREATE OR REPLACE FUNCTION find_or_create_answer(in_response_id bigint, in_section text, in_ttl integer, in_class text, in_type text, in_name text, in_value text, in_opts text)
  RETURNS integer AS
$BODY$DECLARE
    out_answer_id INTEGER := 0;
    norm_name  TEXT := LOWER(in_name);
    norm_value TEXT := LOWER(in_value);
BEGIN
    -- Find this Answer
    select into out_answer_id id from answer
        where class=in_class and type=in_type and name=norm_name and value=norm_value
    limit 1;

    IF NOT FOUND THEN
        -- Create it
        insert into answer ( class, type, name, value, opts )
            values ( in_class, in_type, norm_name, norm_value, in_opts )
        RETURNING id INTO out_answer_id;
        --select into out_answer_id currval('answer_id_seq');
    END IF;

    -- Link the Answer / Response
    PERFORM 1 from meta_answer where response_id = in_response_id AND answer_id = out_answer_id AND section = in_section;
    IF NOT FOUND THEN
        insert into meta_answer ( response_id, answer_id, section, ttl )
            values ( in_response_id, out_answer_id, in_section, in_ttl );
    END IF;

    -- Update the answer tracking data
    update answer set last_ts=NOW(), reference_count=reference_count+1 where id=out_answer_id;

    return out_answer_id;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
