package DreamCatcher::Feather::dns;

use strict;
use warnings;
use Net::DNS::Packet;
use Mouse;
with qw(
    DreamCatcher::Role::Feather
    DreamCatcher::Role::Feather::Sniffer
);

# Override default priority
sub _build_priority { 2; }

sub process {
    my ($self,$packet,$data) = @_;
}

# Return True;
1;
