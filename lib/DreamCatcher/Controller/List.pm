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

sub view {
    my $self = shift;
    my $id   = $self->stash('id');

    my %sql = (
        entries => q{
            SELECT
                le.*
            FROM list_entry AS le
            WHERE le.list_id = ?
        },
        list => q{
            SELECT
                l.*,
                lt.name as type,
                lt.score
            FROM list AS l
                INNER JOIN list_type AS lt ON l.type_id = lt.id
            WHERE l.id = ?
        },
        tracking => q{
            SELECT
                COUNT(1) AS clients,
                MIN(first_ts) AS first_ts,
                MAX(last_ts) AS last_ts,
                SUM(reference_count) AS total
            FROM list_tracking_client AS ltc
            WHERE ltc.list_id = ?
            GROUP BY ltc.list_id
        },
    );

    my %sth = ();
    foreach my $s (keys %sql) {
        $sth{$s} = $self->prepare_statement($sql{$s});
    }
    foreach my $s (qw(list entries tracking)) {
        $sth{$s}->execute($id);
    }

    my @entries = ();
    while( my $e = $sth{entries}->fetchrow_hashref ) {
        push @entries, $e;
    }

    $self->stash(
        list     => $sth{list}->fetchrow_hashref,
        entries  => \@entries,
        tracking => $sth{tracking}->fetchrow_hashref,
    );

    $self->render;
}

1;
