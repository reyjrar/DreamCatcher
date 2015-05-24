package DreamCatcher::Role::Feather::Sniffer;

use Moose::Role;
use namespace::autoclean;

with qw(
    DreamCatcher::Role::Feather
    DreamCatcher::Role::DBH
    DreamCatcher::Role::Cache
    DreamCatcher::Role::Logger
);

requires qw(process);

sub _build_function { 'sniffer'; }

no Moose::Role;
# Return True
1;
