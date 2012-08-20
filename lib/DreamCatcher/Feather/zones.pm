package DreamCatcher::Feather::zones;

use Mouse;
with qw( DreamCatcher::Role::Feather DreamCatcher::Role::Feather::Sniffer );

# Load this after the SQL Feather
sub _build_after { 'sql' }

sub process {
	my ($self,$packet,$data) = @_;
}

# Return True
1;
