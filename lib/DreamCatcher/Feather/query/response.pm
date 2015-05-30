package DreamCatcher::Feather::query::response;
# ABSTRACT: Link query and responses not found in the sniffer

use strict;
use warnings;

use Moose;
use namespace::autoclean;

use DateTime;
use DateTime::Format::Pg;
use POSIX qw(strftime);

with qw(
    DreamCatcher::Role::Feather::Analysis
);

sub _build_interval     { 60 }
sub _build_check_period { 3600*12 }
sub _build_batch_max    { 5_000 }

sub _build_sql {
    return {
		null_response => q{
				select q.* from query q
					left join meta_query_response m on q.id = m.query_id
                    where m.response_id is null
						and q.query_ts > ?
                    order by q.query_ts limit ?
		},
		find_response => q{
			select * from response
				where conversation_id = ?
					and query_serial = ?
					and response_ts between ? and ?
		},
		set_response => q{
			select link_query_response( ?, ?, ?, ? )
		},
        find_questions => q{
            select mq.question_id, ma.answer_id, count(1) as reference_count, min(query_ts) as first_ts, max(response_ts) as last_ts
                from meta_question mq
                    inner join meta_query_response mqr on mq.query_id = mqr.query_id
                    inner join meta_answer ma on mqr.response_id = ma.response_id and ma.section = 'answer'
                    inner join response r on mqr.response_id = r.id
                    inner join query q on mqr.query_id = q.id
                where mqr.query_id = ?
                    and r.status = 'NOERROR'
                group by mq.question_id, ma.answer_id
        },
        link_question_answer => q{
            select link_question_answer(?, ?, ?, ?, ?)
        },
    };
}

sub analyze {
    my ($self) = @_;

	$self->log(debug => sprintf "query::response starting analysis for past %d seconds, max %d records.",
                $self->check_period,
                $self->batch_max,
    );

	my $check_ts = strftime('%FT%T',localtime(time - $self->check_period));

    my %STH = map { $_ => $self->sth($_) } qw(
        null_response find_response set_response
        find_questions link_question_answer
    );

	$STH{null_response}->execute( $check_ts, $self->batch_max );
    $self->log(debug => sprintf "null_response provided %d records to check.", $STH{null_response}->rows);

	my $updates = 0;
    my $errors  = 0;
    my $subdates = 0;
	while( my $q = $STH{null_response}->fetchrow_hashref ) {
		my $qt = DateTime::Format::Pg->parse_datetime( $q->{query_ts} );
		# Find the response
        eval {
            $STH{find_response}->execute( $q->{conversation_id}, $q->{query_serial},
                $qt->clone->datetime,
                $qt->clone()->add( seconds => 10 )->datetime
            );
        };
        if( my $ex = $@ ) {
            $self->log(error => "Lookup for a matching query/response for $q->{id}");
            $self->log(debug => "ERROR: $ex");
            next;
        }
		# If we found 1, do something!
		if( $STH{find_response}->rows == 1 ) {
			my($r) = $STH{find_response}->fetchrow_hashref;
            my @args = (
                    $q->{id},
                    $r->{id},
                    $q->{conversation_id},
                    defined $r->{capture_time} && defined $q->{capture_time} ? $r->{capture_time} - $q->{capture_time} : undef
            );
			eval {
                $STH{set_response}->execute(@args);
            };
            if( my $ex = $@ ) {
                $errors++;
                $self->log(debug => sprintf "ERROR: Linking queries(%s): %s", join(',', @args), $ex);
                next;
            }
            else {
                # Do question/answer discovery
                $STH{find_questions}->execute($q->{id});
                $self->log(debug => sprintf "- query_id:%d found %d questions with answers.", $q->{id}, $STH{find_questions}->rows);

                while( my @fields = $STH{find_questions}->fetchrow_array ) {
                    next and $self->log(debug => "ERROR: $@") unless eval {
                        $STH{link_question_answer}->execute(@fields);
                        1;
                    };
                    $subdates++;
                }
            }
			$updates++;
		}
        elsif( $STH{find_response}->rows > 0 ) {
            $self->log(info => sprintf "Attempting to find responses for query_id:%d yielded %d results.",
                    $q->{id},
                    $STH{find_response}->rows
            );
        }
	}

    $_->finish for values %STH;
	$self->log(info => sprintf "query::response posted %d updates and %d errors, %d questions/answers linked", $updates, $errors, $subdates);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
