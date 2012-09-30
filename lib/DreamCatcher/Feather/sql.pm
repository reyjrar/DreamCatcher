package DreamCatcher::Feather::sql;
# ABSTRACT: Provides Storage in an SQL database

use DBIx::Connector;

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

has dbh => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    builder => '_build_dbh',
);

sub _build_dbh {}

# Return True
1;
