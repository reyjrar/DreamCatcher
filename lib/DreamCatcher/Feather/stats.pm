package DreamCatcher::Feather::stats;
# ABSTRACT: Builds the statistics for the parsing engine

use Mouse;
with qw(
    DreamCatcher::Role::Feather
    DreamCatcher::Role::Feather::Sniffer
);

# After the DNS Parsing occurs
sub _build_after { 'dns'; }

sub process {
	my ($self,$packet,$data) = @_;
}

# Return True
1;
