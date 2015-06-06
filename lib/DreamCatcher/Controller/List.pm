package DreamCatcher::Controller::List;
# ABSTRACT: DreamCatcher List Pages
use Mojo::Base 'DreamCatcher::Controller';

sub index {
    my $self = shift;

    my $sth = $self->prepare_statement(q{
        select l.*,
            lt.name as type,
            (select count(1) from list_entry WHERE list_id = l.id) as entries
        from list l
            inner join list_type lt on l.type_id = lt.id
    });
    $sth->execute();

    my %l = ();
    while ( my $ent = $sth->fetchrow_hashref ) {
        $l{$ent->{id}} = $ent;
    }

    $self->stash(lists => \%l);

    $self->render();
}

1;
