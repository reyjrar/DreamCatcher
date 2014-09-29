package DreamCatcher::Feather::zone::discovery;
# ABSTRACT: Populates zone tables

use Moo;
with qw(
    DreamCatcher::Role::Feather::Analysis
    DreamCatcher::Role::Logger
);
use POSIX qw(strftime);

sub _build_sql {
    return {
        answer => q{
                select a.* from packet_record_answer a
                    left join zone_answer z on a.id = z.answer_id
                where
                    a.class = 'IN'
                    and a.type in ( 'A', 'AAAA', 'PTR', 'MX', 'SOA', 'NS' )
                    and z.answer_id is null
                order by first_ts asc
        },
        question => q{
                select q.* from packet_record_question q
                    left join zone_question z on q.id = z.question_id
                where
                    q.class = 'IN'
                    and q.type in ( 'A', 'AAAA', 'PTR', 'MX', 'SOA', 'NS' )
                    and z.question_id is null
                order by first_ts asc
        },
        zone_id            => q{select get_zone_id( ?, ?, ?, ? )},
        link_zone_answer   => q{select link_zone_answer( ?, ? )},
        link_zone_question => q{select link_zone_question( ?, ? )},
    };
}

sub analyze {
    my ($self) = @_;

    my $check_ts = strftime('%FT%T%z',localtime(time - 86400));
    my %stats = map { $_ => 0 } qw(questions answers);

    # DB Connections
    my %STH = map { $_ => $self->sth($_) } keys %{ $self->sql };

    # Get questions
    $STH{question}->execute();
    while(my $q = $STH{question}->fetchrow_hashref) {
        my ($name,$zone) = split( /\./, $q->{name}, 2 );
        if (! defined $zone ) {
            $self->log(debug =>  "error parsing zone for $q->{id} $q->{class} $q->{type} $q->{name}");
            next;
        }
        my @path = split( /\./, $zone );
        # We want SLD's at the lowest level
        unshift @path, $name if @path == 1;
        my $path = join('.', reverse @path);
        $path =~ s/\-/_/g;

        next if $path =~ /[^a-zA-Z0-9.\_]/; # TODO: utf8 handling

        $STH{zone_id}->execute( $zone, $path, $q->{first_ts}, $q->{last_ts} );
        my ($zone_id) = $STH{zone_id}->fetchrow_array;
        next unless defined $zone_id and $zone_id > 0;
        eval { $STH{link_zone_question}->execute( $zone_id, $q->{id} ); };
        if(my $ex = $@) {
            $self->log(error => sprintf "zone::discovery: linking zone_id(%d) to question(%d) failed: %s",
                $zone_id,
                $q->{id},
                $ex->errstr
            );
            $stats{errors}++;
        }
        else {
            $stats{questions}++;
        }
    }
    $self->log(info => "zone::discovery: questions linked $stats{questions}");

    # Get answers
    $STH{answer}->execute();
    while(my $q = $STH{answer}->fetchrow_hashref) {
        foreach my $field ( qw( name value ) ) {
            next if $q->{$field} =~ /(\d{1,3}\.){3}\d{1,3}/;
            my ($name,$zone) = map { lc } split( /\./, $q->{$field}, 2 );
            if (! defined $zone || ! length $zone ) {
                $self->log(debug =>  "error parsing zone for $q->{id} $q->{class} $q->{type} $q->{name}");
                next;
            }
            my @path = split( /\./, $zone );

            # We want SLD's at the lowest level
            unshift @path, $name if @path == 1;

            my $path = join('.', reverse @path );
            $path =~ s/\-/_/g;
            next if $path =~ /[^a-zA-Z0-9.\-]/; # TODO: utf8 handling

            $STH{zone_id}->execute( $zone, $path, $q->{first_ts}, $q->{last_ts} );
            my ($zone_id) = $STH{zone_id}->fetchrow_array;
            next unless defined $zone_id and $zone_id > 0;
            eval { $STH{link_zone_answer}->execute( $zone_id, $q->{id} ); };
            if(my $ex = $@) {
                $self->log(error => sprintf "zone::discovery: linking zone_id(%d) to answer(%d) failed: %s",
                    $zone_id,
                    $q->{id},
                    $ex->errstr
                );
                $stats{errors}++;
            }
            else {
                $stats{answers}++;
            }
        }
    }
    $self->log(info => "zone::discovery: answers linked $stats{answers}");
}
1;
