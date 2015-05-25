-- Function: link_question_answer(bigint, bigint, integer, timestamp without time zone, timestamp without time zone)

-- DROP FUNCTION link_question_answer(bigint, bigint, integer, timestamp without time zone, timestamp without time zone);

CREATE OR REPLACE FUNCTION link_question_answer(
    in_question_id bigint,
    in_answer_id bigint,
    in_reference_count integer DEFAULT 1,
    in_first_ts timestamp without time zone DEFAULT now(),
    in_last_ts timestamp without time zone DEFAULT now())
  RETURNS void AS
$BODY$BEGIN

    PERFORM 1 FROM meta_question_answer WHERE question_id = in_question_id AND answer_id = in_answer_id;
    IF FOUND THEN
        UPDATE meta_question_answer
            SET reference_count = reference_count + in_reference_count
            AND first_ts = (CASE WHEN first_ts < in_first_ts THEN first_ts ELSE in_first_ts END)
            AND last_ts = (CASE WHEN last_ts > in_last_ts THEN last_ts ELSE in_last_ts END)
        WHERE question_id = in_question_id AND answer_id = in_answer_id;
    ELSE
        INSERT INTO meta_question_answer ( question_id, answer_id, reference_count, first_ts, last_ts )
            VALUES ( in_question_id, in_answer_id, in_reference_count, in_first_ts, in_last_ts );
    END IF;
    RETURN;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
