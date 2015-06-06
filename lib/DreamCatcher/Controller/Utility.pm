package DreamCatcher::Controller::Utility;

# ABSTRACT: DreamCatcher Utility Pages
use Mojo::Base 'DreamCatcher::Controller';

use Net::IP;

sub index {
    my $self = shift;

    $self->render();
}

sub reverse_lookup {
    my $self = shift;

    my $ip = $self->param('ip');

    # Fast check for valid IP Address
    if( $ip !~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ ) {
        $self->flash( error => "Invalid IP address passed to Utility::reverse_lookup");
        $self->redirect_to("/utility");
        return;
    }

    my %sql = (
        reverse_lookup => q{
            select
                id,
                first_ts,
                last_ts,
                name,
                type,
                class,
                value,
                reference_count
            from answer
                where value = ?
        },
    );

    # Prepare SQL
    my $STH = $self->prepare_statements( \%sql );
    # Execute it!
    $STH->{$_}->execute($ip) for keys %{ $STH };

    $self->stash(
        ip  => $ip,
        STH => $STH,
    );

    $self->render("utility/reverse");
}

sub clients_asking {
    my ($self) = shift;

    # Normalize the parts
    my $question = $self->param('question');
    my @parts = split /\s+/, $question;

    my $class = 'IN';
    my $type  = 'A';
    my $name  = $parts[-1];
    my $path = join '.', reverse split /\./, $name;

    if( @parts == 3 ) {
        ($class,$type) = map { uc } @parts[0,1];
    }

    # SQL Queries
    my %sql = (
        question => q{
            select id from question where class = ? and type = ? and name = ?
        },
        zone => q{
            select id from zone where path <@ ?
        },
        clients_question => q{
			select
				ip as client, min(q.query_ts) as first_ts, max(q.query_ts) as last_ts, count(1) as reference_count
			from meta_question mq
				inner join query q on mq.query_id = q.id
				inner join client c on q.client_id = c.id
			where
				mq.question_id = ?
			group by ip
        },
        clients_zone => q{
			select
				ip as client, min(q.query_ts) as first_ts, max(q.query_ts) as last_ts, count(1) as reference_count
			from zone_question zq
				inner join meta_question mq on zq.question_id = mq.question_id
				inner join query q on mq.query_id = q.id
				inner join client c on q.client_id = c.id
			where
				zq.zone_id = ?
			group by ip
        },
    );
    # Prepare SQL
    my $STH = $self->prepare_statements( \%sql );

    # Find the query
    my $by;
    my $id;

    $STH->{question}->execute( $class, $type, $name );
    if( $STH->{question}->rows > 0 ) {
        $by = 'question';
        ($id) = $STH->{question}->fetchrow_array;
    }
    elsif( $STH->{zone}->execute($path) && $STH->{zone}->rows > 0 ) {
        $by = 'zone';
        ($id) = $STH->{zone}->fetchrow_array;
    }

    $STH->{"clients_$by"}->execute($id) if defined $id;

    $self->stash(
        STH      => $STH,
        name     => $name,
        type     => $type,
        class    => $class,
        question => $question,
        by       => $by,
        found    => defined $id && defined $by,
    );
    $self->render('utility/clients_asking');
}

sub client_server_map {
    my ($self,$app) = @_;

    my %sql = (
        conversations => q{
            select
                cv.id as id,
                c.ip as client,
                c.id as client_id,
                s.ip as server,
                s.id as server_id,
                cv.reference_count as total
            from conversation cv
                inner join client c on c.id = cv.client_id
                inner join server s on s.id = cv.server_id
        }
    );
    my $STH = $self->prepare_statements(\%sql);

    $STH->{conversations}->execute();

    my @conversations = ();
    my %nodes = ();
    my $total = 0;
    while ( my $row = $STH->{conversations}->fetchrow_hashref )  {
        push @conversations, $row;
        foreach my $n (qw(client server)) {
            $nodes{$row->{$n}} ||= {};
            my $hash = $nodes{$row->{$n}};
            if( !exists $hash->{x} ) {
                my %c = _coords($row->{$n});
                $hash->{x} = $c{x};
                $hash->{y} = $c{y};
            }
            $hash->{total} += $row->{total};
            $total += $row->{total};
            if( exists $hash->{color} && $hash->{color} eq '#FF0000' ){
                $hash->{color} = '#FF0000';
            }
            else {
                $hash->{color} = $n eq 'server' ? '#FF0000' : '#0174DF';
            }
        }
    }

    foreach my $node (values %nodes) {
        my $ratio = $node->{total} / $total;
        $node->{size} = int($ratio * 10) + 1;
    }
    foreach my $cv (@conversations) {
        my $ratio = $cv->{total} / $total;
        $cv->{size} = int($ratio * 10) + 1;
    }

    $self->stash(
        conversations => \@conversations,
        nodes => \%nodes,
    );
}

my $HALF_IP = 2 ** 16;
sub _coords {
    my ($ip_str) = @_;
    my $ip = Net::IP->new( $ip_str );
    my $as_int = $ip->intip;

    my %coords = (
        x => $as_int % $HALF_IP,
        y => int( $as_int / $HALF_IP ),
    );
    return wantarray ? %coords : \%coords;
}

1;
