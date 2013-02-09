package DreamCatcher::Controller::Utility;
# ABSTRACT: DreamCatcher Utility Pages
use Mojo::Base 'DreamCatcher::Controller';

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
            from packet_record_answer
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

    if( @parts == 3 ) {
        ($class,$type) = map { uc } @parts[0,1];
    }

    # SQL Queries
    my %sql = (
        query => q{
            select id from packet_record_question where class = ? and type = ? and name = ?
        },
        clients_asking => q{
			select
				ip as client, min(q.query_ts) as first_ts, max(q.query_ts) as last_ts, count(1) as reference_count
			from
				packet_meta_question mq
				inner join packet_query q on mq.query_id = q.id
				inner join client c on q.client_id = c.id
			where
				mq.question_id = ?
			group by ip
        },
    );
    # Prepare SQL
    my $STH = $self->prepare_statements( \%sql );

    # Find the query
    $STH->{query}->execute( $class, $type, $name );
    if( $STH->{query}->rows > 0 ) {
        my($id) = $STH->{query}->fetchrow_array;

        $STH->{clients_asking}->execute( $id );
    }

    $self->stash(
        STH      => $STH,
        name     => $name,
        type     => $type,
        class    => $class,
        question => $question,
    );
    $self->render('utility/clients_asking');
}

1;
