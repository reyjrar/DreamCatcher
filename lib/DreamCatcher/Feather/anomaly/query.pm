package DreamCatcher::Feather::anomaly::query;
# ABSTRACT: Calculate anomaly score for a query based on flags and opcodes

use Const::Fast;
use JSON::XS;
use Moo;
with qw(
    DreamCatcher::Role::Feather::Analysis
    DreamCatcher::Role::Feather::Anomaly
    DreamCatcher::Role::Logger
);
use POSIX qw(strftime);

const my %OPCODES => (
    # Raw                   # Name
    1      => 'obsolete',   IQUERY => 'obsolete',
    3      => 'unassigned',
    6      => 'unassigned',
    7      => 'unassigned',
    8      => 'unassigned',
    9      => 'unassigned',
    10     => 'unassigned',
    11     => 'unassigned',
    12     => 'unassigned',
    13     => 'unassigned',
    14     => 'unassigned',
    15     => 'unassigned',
);

sub _build_sql {
    return {
        check => q{
            select
                s.ip as server,
                c.ip as client,
                q.id as query_id,
                q.opcode,
                q.count_questions,
                q.flag_recursive,
                q.flag_checking,
                q.flag_truncated
            from packet_query q
                inner join client c on q.client_id = c.id
                inner join server s on q.server_id = s.id
                left join anomaly_query aq on q.id = aq.query_id
            where
                query_ts > ?
                and aq.query_id is null
        },
        insert => q{
            insert into anomaly_query ( query_id, score, analysis) values ( ?, ?, ? )
        },
    };
}

sub analyze {
    my $self = shift;

    my %STH = map { $_ => $self->sth($_) } keys %{ $self->sql };

    my $time = strftime("%FT%T", localtime(time() - 60*60*12));
    $self->log(info => "anomaly::query checking queries since $time");

	my $updates = 0;
    my $errors  = 0;
	$STH{check}->execute($time);
	while( my $ent = $STH{check}->fetchrow_hashref ) {
        my $score = 0;
        my %analysis = ();

        # Check opcodes
        if(exists $OPCODES{$ent->{opcode}}) {
            my $type = $OPCODES{$ent->{opcode}};
            $score += $self->score($type);
            my $key = sprintf "query_%s_opcode", $type;
            $analysis{$key} = $ent->{opcode};
        }

        # Rare to have more than 1 question in a packet
        if( $ent->{count_questions} > 1 ) {
            my $type = $ent->{count_questions} > 10 ? 'malicious' : 'suspicious';
            my $key  = sprintf "query_%s_questions", $type;
            $score += $self->score($type);
            $analysis{$key} = $ent->{count_questions};
        }

        # Rare to have all flags true
        if( $ent->{flag_recursive} && $ent->{flag_checking} && $ent->{flag_truncated} ) {
            $analysis{query_suspicious_flags} = 'all true';
            $score += $self->score('suspicious');
        }

        # Mark this as done
        eval { $STH{insert}->execute($ent->{query_id},$score,encode_json(\%analysis)) };
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
