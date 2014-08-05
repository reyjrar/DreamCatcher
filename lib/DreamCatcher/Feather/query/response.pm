package DreamCatcher::Feather::query::response;
# ABSTRACT: Link query and responses not found in the sniffer

use strict;
use warnings;
use Moo;
use DateTime;
use DateTime::Format::Pg;

with qw(
    DreamCatcher::Role::Feather::Analysis
    DreamCatcher::Role::Logger
);

sub _build_sql {
    return {
		null_response => q{
				select q.* from packet_query q
					left join packet_meta_query_response m on q.id = m.query_id
						where m.response_id is null
						and q.query_ts > ?
						and q.id > ?
						order by q.query_ts limit 2000
		},
		find_response => q{
			select id from packet_response
				where conversation_id = ?
					and query_serial = ?
					and response_ts between ? and ?
		},
		set_response => q{
			select link_query_response( ?, ? )
		},
    };
}

sub analyze {
    my ($self) = @_;

	$self->log(debug => "query::response starting analysis");

	my $check_ts = DateTime->now()->subtract( hours => 12 );

    my %STH = map { $_ => $self->sth($_) } qw(null_response find_response set_response);

	$STH{null_response}->execute( $check_ts->datetime, $self->last_id );

	my $updates = 0;
	my $id = 0;
	while( my $q = $STH{null_response}->fetchrow_hashref ) {
		my $qt = DateTime::Format::Pg->parse_datetime( $q->{query_ts} );
		# Find the response
        eval {
            $STH{find_response}->execute( $q->{conversation_id}, $q->{query_serial},
                $qt->clone->datetime,
                $qt->clone()->add( seconds => 5 )->datetime
            );
        };
        if( my $ex = $@ ) {
            $self->log(error => "Lookup for a matching query/response failed in __PACKAGE__");
            next;
        }
		# If we found 1, do something!
		if( $STH{find_response}->rows == 1 ) {
			my($response_id) = $STH{find_response}->fetchrow_array;
			eval {
                $STH{set_response}->execute( $q->{id}, $response_id );
            };
            next if $@;
			$updates++;
		}
		$id = $q->{id};
	}
	$self->last_id($id);

	$self->log(info => "query::response posted $updates updates");
}

# Return True;
1;
