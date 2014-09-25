package DreamCatcher::Role::Feather::Sniffer;

use Moo::Role;
use Sub::Quote;

with 'DreamCatcher::Role::Feather';

requires qw(process);

sub _build_function { 'sniffer'; }

# Return True
1;
