package DreamCatcher::Feather::anomaly::query;
# ABSTRACT: Calculate anomaly score for a query based on flags and opcodes

use Const::Fast;
use JSON::MaybeXS;
use Moose;
with qw(
    DreamCatcher::Role::Feather::Analysis
    DreamCatcher::Role::Feather::Anomaly
);
use POSIX qw(strftime);

sub _build_sql {
    return {
        check => q{
            select
                s.ip as server,
                c.ip as client,
                q.id,
                q.opcode,
                q.count_questions,
                q.flag_recursive,
                q.flag_checking,
                q.flag_truncated,
                (select count(1) from meta_question where query_id = q.id) as actual_questions
            from query q
                inner join client c on q.client_id = c.id
                inner join server s on q.server_id = s.id
                left join anomaly_query aq on q.id = aq.id
            where
                query_ts > ?
                and aq.id is null
        },
        insert => q{
            insert into anomaly_query ( source, id, score, checks, results ) values ( 'query', ?, ?, ?, ? )
        },
    };
}

sub analyze {
    my $self = shift;

    my %STH = map { $_ => $self->sth($_) } keys %{ $self->sql };

    my $time = strftime("%FT%T", localtime(time() - $self->check_period));
    $self->log(info => "anomaly::query checking queries since $time");

	my $updates = 0;
    my $errors  = 0;
	$STH{check}->execute($time);
	while( my $ent = $STH{check}->fetchrow_hashref ) {
        my $score   = 0;
        my %analysis = ();

        # Check opcodes
        my $opcode_level = $self->anomaly_opcode($ent->{opcode});
        if(defined $opcode_level && $opcode_level ne 'common') {
            $score += $self->score($opcode_level);
            my $key = sprintf "query_%s_opcode", $opcode_level;
            $analysis{$key} = $ent->{opcode};
        }

        # Rare to have more than 1 question in a packet
        if( $ent->{count_questions} > 1 ) {
            my $type = $ent->{count_questions} > 10 ? 'malicious' : 'suspicious';
            my $key  = sprintf "query_%s_questions", $type;
            $score += $self->score($type);
            $analysis{$key} = $ent->{count_questions};
        }
        if( $ent->{count_questions} != $ent->{actual_questions} ) {
            $score += $self->score('mismatch');
            $analysis{query_mismatch_questions} = $ent->{actual_questions};
        }

        # Rare to have all flags true
        if( $ent->{flag_recursive} && $ent->{flag_checking} && $ent->{flag_truncated} ) {
            $analysis{query_suspicious_flags} = 'all true';
            $score += $self->score('suspicious');
        }

        # Mark this as done
        my @checks = qw(questions opcodes flags);
        eval { $STH{insert}->execute($ent->{id},$score,\@checks,encode_json(\%analysis)) };
        if(my $ex = $@) {
            $self->log(error => "anomaly::query - failed to score $ent->{query_id}: $ex");
            $errors++;
        }
        else {
            $updates++;
        }
    }

	$self->log(info => "anomaly::query posted $updates updates, $errors errors");
}


__PACKAGE__->meta->make_immutable;
