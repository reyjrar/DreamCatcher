package DreamCatcher::Feather::stats::graphite;

use Mouse;
with qw( DreamCatcher::Role::Feather DreamCatcher::Role::Feather::Sniffer );

# Install this after stats
sub _build_after { return 'stats'; }

sub process {
	my ($self,$packet,$data) = @_;
}

# Return True
1;
