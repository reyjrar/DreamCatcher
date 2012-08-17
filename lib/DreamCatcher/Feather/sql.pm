package DreamCatcher::Feather::sql;

use Mouse;
with 'DreamCatcher::Role::Feather';

# Make sure that stats are loaded
sub _build_after { 'stats'; }

sub process {
	my ($self,$packet,$data) = @_;
}

# Return True
1;
