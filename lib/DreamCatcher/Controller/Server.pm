package DreamCatcher::Controller::Server;
# ABSTRACT: DreamCatcher Server Pages
use Mojo::Base 'DreamCatcher::Controller';

sub index {
    my $self = shift;

    my %sql = (
    );
    # Prepare SQL
    my $STH = $self->prepare_statements( \%sql );
    # Execute it!
    $STH->{$_}->execute() for keys %{ $STH };
    # Stash
    $self->stash( STH => $STH );

    $self->common_query( $_ ) for qw{top_servers};

    $self->render();
}

sub view {
    my $self = shift;

    my $id = $self->stash('id');

    my %sql = (
        server => qq{
            select * from server
                where id = ?
        },
        clients => qq{
            select  cli.ip,
                    cv.first_ts,
                    cv.last_ts,
                    cv.reference_count as conversation_count,
                    cli.reference_count as total_count
                from conversation cv
                    inner join client cli on cv.client_id = cli.id
                where cv.server_id = ?
        },

    );

    # Prepare SQL
    my $STH = $self->prepare_statements( \%sql );
    # Execute it!
    $STH->{$_}->execute($id) for keys %{ $STH };

    # TODO: Unknown server handle

    # Stash Details
    $self->stash( server => $STH->{server}->fetchrow_hashref );
    $self->stash( clients_sth => $STH->{clients} );

    $self->render();
}

1;
