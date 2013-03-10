package DreamCatcher::Feather::queryresponse;
# ABSTRACT: Link query and responses not found in the sniffer

use strict;
use warnings;
use Moo;

with qw(
    DreamCatcher::Role::Feather::Analysis
    DreamCatcher::Role::Logger
	DreamCatcher::Role::DBH
);

sub _build_sql {
    return {
    };
}

sub analyze {
    my $self = shift;
}

# Return True;
1;
