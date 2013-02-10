package DreamCatcher::Feather::stats::client;
# ABSTRACT: Store the DNS packet in the database.

use strict;
use warnings;
use Moo;

with qw(
    DreamCatcher::Role::Feather
	DreamCatcher::Role::DBH
);

sub _build_parent { 'conversation'; }

sub process {
    my ($self,$packet) = @_;
}

# Return True;
1;
