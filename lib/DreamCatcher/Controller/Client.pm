package DreamCatcher::Controller::Client;
# ABSTRACT: DreamCatcher Client Pages
use Mojo::Base 'DreamCatcher::Controller';

sub index {
    my $self = shift;
    $self->render();
}

sub view {
    my $self = shift;
    my $id = $self->stash('id');

    my %sql = (
        client => qq{
            select * from client
                where id = ?
        },
        servers => qq{
            select  srv.ip,
                    cv.first_ts,
                    cv.last_ts,
                    cv.reference_count as conversation_count,
                    srv.reference_count as total_count
                from conversation cv
                    inner join server srv on cv.server_id = srv.id
                where cv.client_id = ?
        },

    );

    # Prepare SQL
    my $STH = $self->prepare_statements( \%sql );
    # Execute it!
    $STH->{$_}->execute($id) for keys %{ $STH };

    # TODO: Unknown client handle

    # Stash Details
    $self->stash( client => $STH->{client}->fetchrow_hashref );
    $self->stash( servers_sth => $STH->{servers} );

    $self->render();
}

1;
