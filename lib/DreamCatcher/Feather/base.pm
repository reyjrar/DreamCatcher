package DreamCatcher::Feather::base;

use Mouse;
with qw( DreamCatcher::Role::Feather DreamCatcher::Role::Feather::Sniffer );

# Name is
sub _build_name { 'base'; }
# Highest Priority
sub _build_priority { 1; }
# After None, or this loads first
sub _build_after { 'none'; }

sub process {
	my ($self,$packet,$data) = @_;
}

# Return True
1;
