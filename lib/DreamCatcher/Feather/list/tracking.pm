package DreamCatcher::Feather::list::tracking;
# ABSTRACT: Track clients hitting certain lists

use Moose;
with qw(
    DreamCatcher::Role::Feather::Analysis
);
use POSIX qw(strftime);

sub _build_check_period { 86400*30 }

sub _build_sql {
    return {
        questions => q{
            select  c.id as client_id,
                    lmq.list_id,
                    max(q.query_ts) as last_ts,
                    min(q.query_ts) as first_ts,
                    count(1) as reference_count
            from list_meta_question lmq
                inner join meta_question mq on lmq.question_id = mq.question_id
                inner join query q on mq.query_id = q.id
                inner join client c on q.client_id = c.id
            where
                q.query_ts > ?
            group by lmq.list_id, c.id
        },
        answers => q{
            select  c.id as client_id,
                    lma.list_id,
                    max(r.response_ts) as last_ts,
                    min(r.response_ts) as first_ts,
                    count(1) as reference_count
            from list_meta_answer lma
                inner join meta_answer ma on lma.answer_id = ma.answer_id
                inner join response r on ma.response_id = r.id
                inner join client c on r.client_id = c.id
            where
                r.response_ts > ?
            group by lma.list_id, c.id
        },
        client => q{select list_tracking_client(?,?,?,?,?)},
    };
}

sub analyze {
    my ($self) = @_;

	my $check_ts = strftime('%FT%T',localtime(time - $self->check_period));
	$self->log(debug => sprintf "list::tracking starting analysis for past %d seconds (from %s), max %d records.",
                $self->check_period,
                $check_ts,
                $self->batch_max,
    );
    my $updates = 0;
    my $errors  = 0;

    my %STH = map { $_ => $self->sth($_) } keys %{ $self->sql };
    my %results = ();
    foreach my $type (qw(answers questions)) {
        $STH{questions}->execute($check_ts);
        while( my $ent = $STH{questions}->fetchrow_hashref ) {
            my $id = join(":", $ent->{list_id}, $ent->{client_id});
            if(exists $results{$id})  {
                $results{$id}->{reference_count} += $ent->{reference_count};
                $results{$id}->{first_ts} = $results{$id}->{first_ts} lt $ent->{first_ts} ? $ent->{first_ts}
                                          : $results{$id}->{first_ts};
                $results{$id}->{last_ts}  = $results{$id}->{last_ts}  gt $ent->{last_ts}  ? $ent->{last_ts}
                                          : $results{$id}->{last_ts};
            }
            else {
                $results{$id} = {
                    reference_count => $ent->{reference_count},
                    first_ts        => $ent->{first_ts},
                    last_ts         => $ent->{last_ts},
                };
            }
        }

    }
    foreach my $id (keys %results) {
        my ($list_id,$client_id) = split ':', $id;
        eval {
            $STH{client}->execute($list_id,$client_id, @{$results{$id}}{qw(first_ts last_ts reference_count)});
            $updates++;
            1;
        } or do {
            $self->log(debug => "ERROR: $@");
            $errors++;
        };
    }

    $self->log(info => "list::tracking posted $updates updates, $errors errors.");
}

__PACKAGE__->meta->make_immutable;
