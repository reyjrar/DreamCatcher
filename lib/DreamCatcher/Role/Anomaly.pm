package DreamCatcher::Role::Anomaly;

use Moose::Role;
use namespace::autoclean;

# Interface to Implement
requires qw(
    dbh
    target
    check_name
    check
);

sub create_table {
    my $self = shift;
}

no Moose::Role;
# Return True
1;
