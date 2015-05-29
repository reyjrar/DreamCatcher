package DreamCatcher::Controller::Conversation;
# ABSTRACT: DreamCatcher Conversation Pages
use Mojo::Base 'DreamCatcher::Controller';

sub index {
    my $self = shift;


    $self->render();
}

sub view {
    my $self = shift;
    my $id = $self->stash('id');

    my %sql = (
        meta => q{
            select
                cv.server_id,
                cv.client_id,
                c.ip as client,
                s.ip as server,
                cv.first_ts,
                cv.last_ts,
                cv.reference_count as references
            from conversation cv
                inner join client c on c.id = cv.client_id
                inner join server s on s.id = cv.server_id
            where cv.id = ?
        },
        queries => q{
            select
                q.query_ts as query_ts,
                q.query_serial as serial,
                q.client_port as client_port,
                q.server_port as server_port,
                q.opcode as opcode,
                q.flag_recursive, q.flag_truncated, q.flag_checking,
                qs.class as qclass,
                qs.type as qtype,
                qs.name as qname,
                mqr.response_id,
                r.status as status,
                mqr.timing as took

            from conversation cv
                inner join query q on q.conversation_id = cv.id
                inner join meta_question mq on q.id = mq.query_id
                inner join question qs on mq.question_id = qs.id
                left  join meta_query_response mqr on q.id = mqr.query_id
                left  join response r on mqr.response_id = r.id
            where cv.id = ?
                order by q.query_ts DESC
                limit 1000
        },
        responses => q{
            select
                r.response_ts,
                r.client_port,
                r.server_port,
                r.query_serial as serial,
                r.opcode as opcode,
                a.class as aclass,
                a.type as atype,
                a.name as aname,
                a.value as value,
                a.opts as opts,
                r.status as status,
                r.flag_authoritative, r.flag_recursion_available,
                ma.section as section,
                mqr.timing as took

            from conversation cv
                inner join response r on r.conversation_id = cv.id
                left join meta_query_response mqr on r.id = mqr.response_id
                left join meta_answer ma on r.id = ma.response_id
                left join answer a on ma.answer_id = a.id
            where cv.id = ?
                order by r.response_ts DESC
                limit 1000
        },
    );

    # Prepare SQL
    my $STH = $self->prepare_statements( \%sql );
    # Execute it!
    $STH->{$_}->execute($id) for keys %{ $STH };

    # Stash Details
    $self->stash(
        meta         => $STH->{meta}->fetchrow_hashref,
        query_sth    => $STH->{queries},
        response_sth => $STH->{responses},
    );

    $self->render();
}

1;
