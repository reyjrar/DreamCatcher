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
                pq.query_ts as query_ts,
                pq.client_port as client_port,
                pq.server_port as server_port,
                pq.opcode as opcode,
                pq.flag_recursive, pq.flag_truncated, pq.flag_checking,
                prq.class as qclass,
                prq.type as qtype,
                prq.name as qname,
                pmqr.response_id,
                pr.status as status

            from conversation cv
                inner join packet_query pq on pq.conversation_id = cv.id
                inner join packet_meta_question pmq on pq.id = pmq.query_id
                inner join packet_record_question prq on pmq.question_id = prq.id
                left  join packet_meta_query_response pmqr on pq.id = pmqr.query_id
                left  join packet_response pr on pmqr.response_id = pr.id
            where cv.id = ?
                order by pq.query_ts DESC
                limit 1000
        },
        responses => q{
            select
                pr.response_ts,
                pr.client_port,
                pr.server_port,
                pr.opcode as opcode,
                pra.class as aclass,
                pra.type as atype,
                pra.name as aname,
                pra.value as value,
                pra.opts as opts,
                pr.status as status,
                pr.flag_authoritative, pr.flag_recursion_available,
                pt.difference as took

            from conversation cv
                inner join packet_response pr on pr.conversation_id = cv.id
                left join packet_meta_answer pma on pr.id = pma.response_id
                left join packet_record_answer pra on pma.answer_id = pra.id
                left join packet_timing pt on pr.id = pt.response_id
            where cv.id = ?
                order by pr.response_ts DESC
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
