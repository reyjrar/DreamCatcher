package DreamCatcher::Feather::packet::timing;
# ABSTRACT: Calculate timing data between questions and answers

use Moose;
with qw(
    DreamCatcher::Role::Feather::Analysis
);
use POSIX qw(strftime);

sub _build_interval { 90 };

sub _build_sql {
    return {
		check => q{select
					 q.id as query_id, q.conversation_id, qr.response_id, r.capture_time - q.capture_time as difference
						from query q
							inner join meta_query_response qr on q.id = qr.query_id
							left  join packet_timing t on q.id = t.query_id
							inner join response r on qr.response_id = r.id
						where
                            t.query_id is null
                            and q.capture_time is not null
							and q.query_ts > NOW() - interval '2 hours'
                            and r.capture_time is not null
		},
		insert => q{insert into packet_timing ( conversation_id, query_id, response_id, difference )
						values ( ?, ?, ?, ? )
		},
    };
}

sub analyze {
    my ($self) = @_;

    my %STH = map { $_ => $self->sth($_) } keys %{ $self->sql };
	$STH{check}->execute();

	my $updates = 0;
    my $errors  = 0;
	while( my $ent = $STH{check}->fetchrow_hashref ) {
		eval { $STH{insert}->execute( $ent->{conversation_id}, $ent->{query_id}, $ent->{response_id}, $ent->{difference} ) };
        if(my $ex = $@) {
            $self->log(error => sprintf "Error handling timing data for conversation_id(%d) and query_id(%d): %s",
                $ent->{conversation_id},
                $ent->{query_id},
                $ex->errstr,
            );
            $errors++;
        }
        else {
            $updates++;
        }
	}
	$self->log(info => "packet::timing posted $updates updates, $errors errors");
}

__PACKAGE__->meta->make_immutable;
