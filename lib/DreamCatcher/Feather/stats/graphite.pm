package DreamCatcher::Feather::stats::graphite;

use Mouse;
with 'DreamCatcher::Role::Feather';

# Install this after stats
sub _build_after { return 'stats'; }

sub process {
	my ($self,$packet,$data) = @_;
}

# Return True
1;
