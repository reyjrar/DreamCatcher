package DreamCatcher::Feather::conversation;
# ABSTRACT: Determine which conversation this packet belongs to.

use strict;
use warnings;
use Mouse;
with qw(
    DreamCatcher::Role::Feather
);

# Override default priority
sub _build_priority { 1; }

sub process {
    my ($self,$packet) = @_;

    $packet->details->{conversation_id} = 1;
}

# Return True;
1;
