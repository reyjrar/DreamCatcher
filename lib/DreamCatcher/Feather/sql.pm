package DreamCatcher::Feather::sql;
# ABSTRACT: Provides Storage in an SQL database

use Mouse;
with qw(
    DreamCatcher::Role::Feather
    DreamCatcher::Role::Feather::Sniffer
);

# Make sure that stats are loaded
sub _build_after { 'stats'; }

sub process {
	my ($self,$packet,$data) = @_;
}

# Return True
1;
